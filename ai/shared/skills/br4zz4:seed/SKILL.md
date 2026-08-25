---
name: br4zz4:seed
description: Use when creating or reviewing seeds or factories.
version: 1.0.0
---

# commons:seed

> **TLDR**: Every feature must have its data represented in fixtures/factories and seeds so the dev environment stays usable.

## Rules

- Seeds live in `seeds.<stack>` — see stack-specific paths below
- Factories are for tests; seeds are for the dev environment — both are required
- Seeds must be idempotent: running them twice must not duplicate data
- Seeds must be dev-only: add `return unless Rails.env.development?` (Ruby) or equivalent at the top
- Never hardcode IDs — use lookups or let the database generate them
- Keep seed data minimal but realistic enough to exercise the feature
- Follow the rule in `@../../rules/shared/seeds.md`

## Stack paths

| Stack | Factories / Fixtures | Seeds |
|-------|----------------------|-------|
| Ruby (Rails) | `test/factories/<model>.rb` (FactoryBot) | `db/seeds/` or `db/seeds.rb` |
| Elixir (Phoenix) | `test/support/factory.ex` | `priv/repo/seeds.exs` |
| Django | `<app>/tests/factories.py` (factory_boy) | `<app>/fixtures/<model>.json` or `scripts/seed.py` |
| React | `src/__tests__/fixtures/<feature>.ts` | N/A (frontend only) |

## Steps

### 1. Identify the feature

Check what was implemented — look at changed files via `git diff --name-only HEAD`.

### 2. Determine what data the feature needs

List the models/entities introduced or changed. For each one, determine:

- What fields are required
- What relationships exist
- What states are relevant (e.g. active/inactive, pending/approved)

### 3. Create or update factories

Add or update factory entries so tests can build the feature's data:

- One factory per model
- Cover the main states of the model as traits or separate factories
- Keep defaults sensible — specific tests override what they need

### 4. Create or update seeds

Add or update seed data in the stack's seed file/directory:

- Include at least one realistic example per model
- If the feature has multiple states, seed one example per meaningful state
- Guard against non-development environments at the top of the file:
  - Ruby: `return unless Rails.env.development?`
  - Elixir: `if Mix.env() != :dev, do: exit(:normal)`
  - Django: guard with `settings.DEBUG` or an env check
- Wrap each record in a guard to avoid duplicates:
  - Ruby: `Model.find_or_create_by!(...)`
  - Elixir: `Repo.insert!(%Model{...}, on_conflict: :nothing)`
  - Django: `Model.objects.get_or_create(...)`

### 5. Add seed to Procfile.dev (if not present)

Every Rails project must have a `seed:` entry in `Procfile.dev`, alongside `migration:`:

```
web: bundle exec rails server -b 0.0.0.0
worker: bundle exec good_job start --enable-cron
setup: bundle exec rails db:prepare && bundle exec rails db:seed
```

- `setup:` combines migration + seed in sequence — seed only runs after migrations complete
- `web:` and `worker:` are long-running processes
- Seeds run automatically on every `make run.server` via overmind, so they must always be idempotent
- Do **not** add seed to `release:` in the production `Procfile`

### 6. Add a final summary

At the end of the seed file, always print a summary block with counts for every seeded model. If the project has user types (admins, members, etc.), list each type with their login credentials so the developer knows how to sign in.

```ruby
puts "\n" + "=" * 80
puts "=== SEED SUMMARY ==="
puts "=" * 80

puts "\n--- ModelName ---"
puts "Total: #{ModelName.count}"
puts "  State A: #{ModelName.where(status: :state_a).count}"
puts "  State B: #{ModelName.where(status: :state_b).count}"

# repeat for each seeded model

puts "\n--- Users ---"
puts "  admin@example.com     / password123  (Admin)"
puts "  member@example.com    / password123  (Member)"

puts "\n" + "=" * 80
```

Rules:
- Always include a `Total:` line per model
- Break down by meaningful states (e.g. paid/pending, active/inactive) when applicable
- If the project seeds users, list every user type with email, password, and role at the end of the summary
- Place the summary block after all seed logic, inside the transaction

### 7. Run seeds to verify

```
make run.seed    # or the project equivalent
```

Run twice to confirm idempotency — no errors or duplicate records on the second run.

### 8. Verify factories in tests

Run the test suite to confirm the factories work:

```
make t
```
