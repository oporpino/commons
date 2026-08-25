---
name: br4zz4:rails
description: Use when writing or reviewing Rails code.
version: 1.4.0
---

# commons:rails

> **TLDR**: Arrow Architecture in Rails — `core/ports/bridges/platform` folders, u-case actions named as the business speaks, explicit orchestration (no `flow`), async effects via transactional outbox.

Principles and laws live in `commons:patterns` § Arrow Architecture. This skill is the Rails application of them.

## Setup

```ruby
# Gemfile
gem "u-case", "~> 4.5", require: "u-case/with_activemodel_validation"
gem "good_job"
# with RabbitMQ: gem "bunny" (publish) + gem "sneakers" (consume)
```

```ruby
# config/application.rb — every app/* subdir is already an autoload root;
# nested roots need registering so folder names never become namespaces:
# core/models/cart.rb → Cart (not Models::Cart)
# core/use_cases/cart/checkout.rb → Cart::Checkout (not UseCases::Cart::Checkout)
%w[core/models core/use_cases].each do |dir|
  path = root.join("app/#{dir}")
  config.autoload_paths << path
  config.eager_load_paths << path
end

%w[controllers jobs consumers serializers].each do |dir|
  path = root.join("app/ports/#{dir}")
  config.autoload_paths << path
  config.eager_load_paths << path
end

config.good_job.enable_cron = true
config.good_job.cron = {
  event_relay: { cron: "* * * * *", class: "EventRelayJob" }
}
```

## Folder layout

```
app/
  core/                  # the business
    models/              # entities: state + invariants
      cart.rb            # Cart (ActiveRecord)
      order.rb
      event.rb           # fact record
    use_cases/           # actions: entry points and steps, by noun
      cart/checkout.rb   # Cart::Checkout — use case (entry point)
      cart/checkout/validate_stock.rb  # flow-private step
      payment/charge.rb  # reusable noun-level verb
  bridges/               # outside parties' knowledge (both directions)
    hotmart/payment_status.rb
    hotmart/verify_signature.rb
    hotmart/parse_webhook.rb
    mailers/order_confirmation.rb
    rabbit/publish.rb    # broker protocol (AMQP)
    webhooks/deliver.rb  # outbound webhook to partners
  platform/              # transport: connects one arrow to the next
    subscriptions.rb     # the map: which fact triggers which reactions
    event_relay_job.rb
    event_handler_job.rb
    dead_letter.rb
  ports/                 # our surface
    controllers/checkouts_controller.rb
    controllers/webhooks/hotmart_controller.rb
    jobs/
    consumers/order_events_consumer.rb
    serializers/order_serializer.rb
```

`rails generate` still writes to the default folders — create files by hand in the right layer.

## Ports

A controller does exactly: authenticate, extract params, call **one** use case, render by result with the correct HTTP status. Zero business ifs, zero direct queries, zero calls to bridges.

```ruby
# BAD — business logic in the controller
class CheckoutsController < ApplicationController
  def create
    cart = current_user.cart
    if cart.items.any? { |i| i.stock <= 0 }
      render json: { error: "out of stock" }, status: :unprocessable_entity and return
    end
    order = Order.create!(cart: cart)
    OrderMailer.confirmation(order).deliver_later
    render json: order, status: :created
  end
end

# GOOD — thin: one use case, render by result
class CheckoutsController < ApplicationController
  def create
    result = Cart::Checkout.call(cart: current_cart, payment_method: params[:payment_method])

    if result.success?
      render json: OrderSerializer.new(result.data[:order]), status: :created
    else
      render json: { errors: result.data[:errors] }, status: :unprocessable_entity
    end
  end
end
```

Serializers are ports (they translate core → HTTP shape), not libs. Jobs and consumers follow the same shape: deserialize, call one use case, translate the result to the transport's vocabulary (retry/ack/requeue).

```ruby
# app/ports/consumers/order_events_consumer.rb — broker consumer (sneakers): same shape
class OrderEventsConsumer
  include Sneakers::Worker
  from_queue "billing.order_placed",
             exchange: "app.events", exchange_type: :topic,
             routing_key: "order.placed"

  def work(raw)
    payload = JSON.parse(raw)
    result = Order::SendConfirmation.call(event: Event.find(payload["event_id"]))
    result.success? ? ack! : requeue!
  end
end
```

## Core

One use case = one class = one action someone performs, named noun + verb: `Cart::Add`, `Cart::Checkout`, `Auth::Login`. Never `CartService`, `CartManager`, `process(action:)`.

`flow` is banned — it hides where errors come from. Orchestration is explicit guard clauses:

```ruby
# app/core/use_cases/cart/checkout.rb — ENTRY POINT: only composes, may cross nouns
class Cart::Checkout < Micro::Case
  attributes :cart, :payment_method

  def call!
    stock = Cart::Checkout::ValidateStock.call(cart: cart)
    return stock if stock.failure?

    charge = Payment::Charge.call(cart: cart, payment_method: payment_method)
    return charge if charge.failure?

    order = nil
    transaction do
      order = Order.create!(cart: cart, charge_id: charge.data[:charge_id])
      Event.create!(name: "order.placed", payload: { order_id: order.id })
    end

    Success result: { order: order }
  end
end
```

Steps do one thing and never call another use case. Flow-private steps nest under the action (`Cart::Checkout::ValidateStock`); reusable verbs live at noun level (`Payment::Charge`). Entry points never call entry points — flatten, or the second flow is a reaction → event.

### Entities — two persistence variants

**Variant A — ActiveRecord in core (default).** The entity is the AR model. Less code, Rails-native:

```ruby
# app/core/models/cart.rb
class Cart < ActiveRecord::Base
  has_many :items, class_name: "CartItem"

  def checkout_ready?
    items.any? && status == "open"
  end

  def total
    items.sum { |i| i.quantity * i.unit_price }
  end
end
```

**Variant B — core isolated from persistence by composition.** The entity is a PORO wrapping a record; the record lives in bridges (the database schema treated as outside knowledge — it knows tables and SQL, nothing else):

```ruby
# app/bridges/cart_record.rb
class CartRecord < ActiveRecord::Base
  self.table_name = "carts"
  has_many :item_records, class_name: "CartItemRecord"
end
```

```ruby
# app/core/models/cart.rb
class Cart
  def self.find(id)
    new(CartRecord.find(id))
  end

  def self.where(**conditions)
    CartRecord.where(**conditions).map { |record| new(record) }
  end

  def initialize(record)
    @record = record
  end

  def id
    @record.id
  end

  def checkout_ready?
    @record.item_records.any? && @record.status == "open"
  end

  def total
    @record.item_records.sum { |i| i.quantity * i.unit_price }
  end

  def mark_as_paid!
    @record.update!(status: "paid")
  end
end
```

Rules for variant B:

- `Cart.find` and `Cart.where` are the only doors — nothing outside `app/core/models/cart.rb` references `CartRecord`
- Delegate only methods the code actually uses; never expose the whole schema because it exists
- A new attribute becomes a method on `Cart` — never reach into `@record` from outside
- Raw associations (`item_records`) never leave the entity; if items must be exposed, wrap them too

Choosing: A is the default. Move to B when the domain must survive schema churn or the table no longer mirrors the business concept — the cost is a delegation layer maintained by hand. Behavior must be identical either way: a shared test asserting the business methods (`checkout_ready?`, `total`) return the same results with the same data is what proves a migration changed structure, not behavior.

### Validations

```ruby
# app/core/models/user.rb — invariant: a user row can NEVER exist without email
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
end

# Use case — context: coupon code is required only when applying a coupon
class Cart::ApplyCoupon < Micro::Case
  attributes :cart, :coupon_code

  validates :coupon_code, presence: true

  def call!
    # ...
  end
end
```

## Bridges

Wrap every outside party; also `Micro::Case` (uniform contract). Translate their vocabulary into ours; capture infra errors into `Failure`; never decide business.

```ruby
# app/bridges/hotmart/payment_status.rb
class Hotmart::PaymentStatus < Micro::Case
  attributes :email

  validates :email, presence: true

  def call!
    user = fetch_user
    return Failure result: { error: "user not found" } if user.nil?

    Success result: { overdue: user["status"] == "BLOCKED" }   # our vocabulary out
  rescue Faraday::Error => e
    Failure result: { error: e.message }
  end
end
```

`overdue: true` leaves; `status: "BLOCKED"` never leaks upward. Who blocks the login is `Auth::Login` — the bridge answers, the use case decides.

## Platform — events

Event contract (see `commons:patterns` § The core's I/O contract): name is a fact in the past tense owned by the noun whose state changed; payload carries ids and the changed fields; the row is immutable once created.

```ruby
# app/core/models/event.rb — the fact: past tense, our vocabulary, immutable
class Event < ApplicationRecord
  attr_readonly :name, :payload, :external_id

  validates :name, :payload, presence: true
  validates :name, format: { with: /\A[a-z_]+\.[a-z_]+\z/ }   # noun.fact_in_past

  scope :pending, -> { where(relayed_at: nil) }
end
# migration: name:string, payload:jsonb, external_id:string (unique index, null allowed),
#            relayed_at:datetime, processed_at:datetime
```

```ruby
# app/platform/subscriptions.rb — the routes.rb of events: fact → reactions
module Subscriptions
  INTERNAL = {
    "order.placed"     => ["Order::SendConfirmation", "Inventory::Reserve"],
    "payment.refunded" => ["Order::Cancel"]
  }.freeze

  EXTERNAL = ["order.placed", "payment.settled"].freeze

  def self.internal_for(event)
    INTERNAL.fetch(event.name, [])
  end

  def self.external?(event)
    EXTERNAL.include?(event.name)
  end
end
```

```ruby
# app/platform/event_relay_job.rb — routing only: zero dialect, zero business
class EventRelayJob < ApplicationJob
  def perform
    Event.pending.find_each do |event|
      Subscriptions.internal_for(event).each do |use_case|
        EventHandlerJob.perform_later(use_case, event.id)
      end
      Rabbit::Publish.call(event: event) if Subscriptions.external?(event)
      event.update!(relayed_at: Time.current)
    end
  end
end
```

The relay enqueues `EventHandlerJob` directly — both live in platform, no layer boundary crossed, so no wrapper. External broadcast crosses to the broker, so it goes through the bridge.

```ruby
# app/platform/event_handler_job.rb — delivers ONE reaction; retries, then dead-letters
class EventHandlerJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
    use_case, event_id = job.arguments
    DeadLetter.create!(event_id: event_id, use_case: use_case, error: error.message)
  end

  def perform(use_case_name, event_id)
    result = use_case_name.constantize.call(event: Event.find(event_id))
    raise result.data[:error].to_s if result.failure?
  end
end
```

```ruby
# app/platform/dead_letter.rb — a delivery that gave up; the fact stays intact in events
class DeadLetter < ApplicationRecord
  belongs_to :event

  def redeliver!
    EventHandlerJob.perform_later(use_case, event_id)
    destroy!
  end
end
```

```ruby
# app/bridges/rabbit/publish.rb — broker protocol lives in a bridge
class Rabbit::Publish < Micro::Case
  attribute :event

  def call!
    exchange.publish(
      { event_id: event.id, name: event.name, payload: event.payload }.to_json,
      routing_key: event.name, persistent: true
    )
    Success result: { published: event.name }
  rescue Bunny::Exception => e
    Failure result: { error: e.message }
  end

  private

  def exchange
    Rabbit::Connection.channel.topic("app.events", durable: true)
  end
end
```

Delivery is at-least-once on every transport — idempotency lives in the reacting use case:

```ruby
# app/core/use_cases/order/send_confirmation.rb
class Order::SendConfirmation < Micro::Case
  attribute :event

  def call!
    return Success(:already_processed) if event.processed_at.present?

    order = Order.find(event.payload["order_id"])

    delivery = Mailers::OrderConfirmation.call(order: order)
    return delivery if delivery.failure?

    event.update!(processed_at: Time.current)
    Success result: { order: order }
  end
end
```

`constantize` receives only `Subscriptions` strings, never external input. GoodJob enqueues are transactional (Postgres) — do not use that to skip the Event table: you lose the fact record, the subscriptions map and the broker route.

## Webhooks

Inbound — the endpoint is ours (ports); the vendor dialect lives in bridges:

```ruby
# app/ports/controllers/webhooks/hotmart_controller.rb — zero vendor knowledge
class Webhooks::HotmartController < ApplicationController
  def create
    result = Webhook::Receive.call(headers: signature_headers, payload: request.raw_post)

    result.failure?(:invalid_signature) ? head(:unauthorized) : head(:ok)
  end
end
```

```ruby
# app/core/use_cases/webhook/receive.rb — entry point: verify, translate, record the fact, answer fast
class Webhook::Receive < Micro::Case
  attributes :headers, :payload

  def call!
    signature = Hotmart::VerifySignature.call(headers: headers, payload: payload)
    return Failure(:invalid_signature) if signature.failure?

    parsed = Hotmart::ParseWebhook.call(payload: payload)
    return Success(:ignored) if parsed.failure?

    Event.create!(
      name: parsed.data[:name],
      payload: parsed.data[:payload],
      external_id: parsed.data[:external_id]
    )
    Success result: { received: true }
  rescue ActiveRecord::RecordNotUnique
    Success(:duplicate)
  end
end
```

```ruby
# app/bridges/hotmart/parse_webhook.rb — all vendor dialect lives here
class Hotmart::ParseWebhook < Micro::Case
  EVENTS = { "PURCHASE_REFUNDED" => "payment.refunded" }.freeze

  attribute :payload

  def call!
    data = JSON.parse(payload)
    name = EVENTS[data["event"]]
    return Failure(:unknown_event) if name.nil?

    Success result: {
      name: name,
      external_id: data["id"],
      payload: { email: data.dig("data", "buyer", "email") }
    }
  end
end
```

Reactions go through the relay as usual. Outbound webhooks (we POST to their endpoint) are `Webhooks::Deliver` in bridges, triggered by the event flow.

## Environments (k8s)

WeHive Rails projects use three environments: `development`, `staging`, `production`.

**`staging`** is a first-class Rails environment — not an alias for production. Create `config/environments/staging.rb` explicitly:

```ruby
# config/environments/staging.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.assume_ssl = true
  config.force_ssl = true
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = true
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false

  if ENV["RAILS_ALLOWED_HOSTS"].present?
    config.hosts = ENV["RAILS_ALLOWED_HOSTS"].split(",").map(&:strip)
  end

  # Exclude health check from host authorization (k8s probes use pod IP as host)
  config.host_authorization = { exclude: ->(request) { request.path == "/health" || request.path == "/up" } }
end
```

**`production.rb`** is identical but with `log_level=info` and `report_deprecations=false`.

**`config.hosts`** is always configured via `RAILS_ALLOWED_HOSTS` env var — injected by k8s per environment overlay. Never hardcode hostnames in the config file.

**k8s base deployment** sets `RAILS_ENV=production` as default. Each overlay patch overrides to `staging` or keeps `production`:

```yaml
# base: RAILS_ENV=production (safe default)
# overlays/staging/patches/deployment.yaml: RAILS_ENV=staging
# overlays/production/patches/deployment.yaml: RAILS_ENV=production (explicit)
```

## Credentials

Only production has its own credentials file. Staging uses the default credentials.

| Environment | Credentials file | Key source |
|---|---|---|
| `development` | `config/credentials.yml.enc` | `config/master.key` (gitignored) |
| `staging` | `config/credentials.yml.enc` | `RAILS_MASTER_KEY` env var (from k8s secret) |
| `production` | `config/credentials/production.yml.enc` | `RAILS_MASTER_KEY` env var (from k8s secret) |

**Rules:**
- Never create `config/credentials/staging.yml.enc` — staging shares the default credentials
- `config/credentials/production.yml.enc` is committed (encrypted); the key is in ward and injected via k8s secret
- `RAILS_MASTER_KEY` in the k8s secret must match the key used to encrypt the credentials file for that environment

**Setup:**
```bash
# Edit default credentials (used by development + staging)
bin/rails credentials:edit

# Edit production credentials
bin/rails credentials:edit --environment production
```

The `RAILS_MASTER_KEY` in the k8s secret (`nectar-charges-secrets`) is the **default** master key (`config/master.key`) — Rails uses it for both development and staging. Production uses a separate key stored under `credentials/production.key` (gitignored, in ward).

## Console sandbox (production/staging)

O Rails console em production e staging deve rodar em sandbox por default para evitar alterações acidentais.

**Implementação via initializer:**

```ruby
# config/initializers/console.rb
Rails.application.configure do
  console do
    next if ENV["CONSOLE_SANDBOX"] == "false"
    next unless Rails.env.production? || Rails.env.staging?

    puts "\e[33m[console] sandbox mode — changes will be rolled back on exit\e[0m"
    puts "\e[33m[console] set CONSOLE_SANDBOX=false to disable\e[0m"

    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    at_exit { ActiveRecord::Base.connection.rollback_transaction }
  end
end
```

**Convenção `CONSOLE_SANDBOX`:**
- Agnóstica de linguagem — o mesmo padrão se aplica a Django, Node, etc.
- Default: sandbox ativo em production e staging
- Para desativar: `CONSOLE_SANDBOX=false bin/rails console`
- Devs seniors usam `CONSOLE_SANDBOX=false` quando precisam persistir mudanças

**Como acessar o console via make:**
- `make console.staging` → readonly + sandbox ativo
- `make console.production` → readonly + sandbox ativo
- `make console.staging.fullaccess` → fullaccess + sandbox desligado (requer ser owner no access.yml)
- `make console.production.fullaccess` → fullaccess + sandbox desligado (requer ser owner no access.yml)

O script `console.sh` injeta `DATABASE_URL` e `CONSOLE_SANDBOX` automaticamente no pod temporário — não precisa configurar manualmente.

## Review checklist

- Would a PM understand the file tree?
- Any business `if` in a controller?
- Any core file mentioning HTTP, params, or vendor names?
- Any use case crossing nouns without being the entry point?
- Every async effect an `Event`?
- Every outside call wrapped in a bridge returning `Success/Failure`?
