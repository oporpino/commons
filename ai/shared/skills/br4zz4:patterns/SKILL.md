---
name: br4zz4:patterns
description: Apply when writing or reviewing any code.
version: 1.4.0
---

# commons:patterns

> Write code that makes you proud. Simple, readable, maintainable. A senior doesn't write more — they write better.

## Core Principles

### SOLID
- **S** — Single Responsibility: each function, module, or type does one thing
- **O** — Open/Closed: extend behavior without modifying existing code
- **L** — Liskov Substitution: subtypes must honor the contract of the type they replace
- **I** — Interface Segregation: small, focused interfaces over fat ones
- **D** — Dependency Inversion: depend on abstractions, not concrete implementations

### DRY — Don't Repeat Yourself
- Every piece of logic exists in exactly one place
- If you write the same thing twice, extract it
- Duplication is a maintenance liability

### KISS — Keep It Simple, Stupid
- The simplest solution that works is the right solution
- Complexity must be justified — if it can't be explained simply, rethink it
- Prefer flat over nested, direct over indirect

### Clean Code
- Names reveal intent: `install_recipe`, not `do_thing`
- Functions do one thing and do it well
- Short functions — if it doesn't fit on a screen, split it
- No comments explaining *what* — code must be self-explanatory
- Comments only for *why* when the reason isn't obvious from context

---

## How to Apply

When writing or reviewing code, ask:

1. **Does this have a single responsibility?** If you struggle to name it in one word, it does too much
2. **Is this written twice?** Extract it
3. **Is this the simplest solution?** Remove every layer that isn't earning its complexity
4. **Would a junior understand this in 30 seconds?** If not, simplify or add a *why* comment

---

## Code Smells to Eliminate

| Smell | Fix |
|-------|-----|
| Function with 3+ levels of nesting | Extract inner logic to named functions |
| Function doing I/O + logic | Separate pure logic from side effects |
| Large match/switch with repeated branches | Extract shared logic, keep branches minimal |
| Comments explaining *what* the code does | Rewrite the code to be self-explanatory |
| Copy-pasted logic | Extract to a shared function |
| Unnecessary abstractions | Inline when used only once |
| Deep parameter drilling | Group into a struct or pass context |

---

## Senior Mindset

- **Less is more**: a solution with fewer lines is almost always better
- **Delete aggressively**: unused code is a liability, not a backup
- **Abstractions must earn their place**: only abstract when you have 2+ concrete cases
- **Readability over cleverness**: the next reader matters more than showing off
- **Name things precisely**: vague names hide poor design

---

## Valid Examples

```rust
// BAD — does too much, repeated logic, vague name
fn do_install(r: &Recipe) {
    if r.meta.kind == RecipeKind::Brew {
        run_cmd(&format!("brew install {}", r.meta.name)).unwrap();
    } else {
        if let Some(cmd) = &r.install.as_ref().unwrap().macos {
            run_cmd(cmd).unwrap();
        }
    }
}

// GOOD — single responsibility, no repetition, reads like prose
fn install(recipe: &Recipe) -> RunResult {
    let steps = recipe.install_steps_for(&platform::detect());
    if steps.is_empty() { return RunResult::NotSupported; }
    steps.iter().try_for_each(|step| platform::current().install(step))
        .map(|_| RunResult::Installed)
        .unwrap_or_else(|e| RunResult::Failed(e.to_string()))
}
```

---

## Arrow Architecture

> Explicit arrows, single dependency direction, no hidden indirection. Language-agnostic — Rails application lives in `commons:rails`.

### Four layers, defined by knowledge

Each layer is a real folder. What defines it is the **knowledge the code holds** — never traffic direction:

> **ports** = where the world talks to us · **core** = what we decide · **bridges** = what we know about each outside party · **platform** = connects one arrow to the next

| Layer | Holds | Examples |
|-------|-------|----------|
| `ports` | our surface: routes, statuses, our queues | HTTP handlers, job entry points, queue consumers, serializers |
| `core` | the business: entities, use cases, facts | `Cart`, `Cart::Checkout`, `Event` |
| `bridges` | outside parties' knowledge, both directions | payment API wrapper, mail delivery, webhook signature/parsing |
| `platform` | cross-cutting transport machinery | event relay, generic handler, subscriptions map, dead letters |

### Dependency rules (no exceptions)

- ports → core only
- core → bridges only, via the uniform contract `call(input) → Result(success | failure, data)`
- platform → core (selects pending facts, runs subscribed use cases) and platform → bridges (external broadcast)
- bridges know nobody; nobody knows platform (it wakes by cron/queue, not by user intent)
- Nothing in core mentions transport, protocols, or vendor payloads

### Placement rules

- Requests we **receive** = ports (we host the endpoint); requests we **make** = bridges (they host it)
- Everything arriving at ports comes from outside — that is what ports are for. `bridges` are not "what comes from outside" but "what we know about specific outsiders": their auth scheme, their payload shape, their event names, their URLs
- Platform is transversal: no request flows through it; it runs beneath the request flow connecting facts to reactions

### Core laws

1. Every port calls exactly one use case: the **entry point** — the feature in code
2. Only the entry point may cross nouns — it is the mediator that sees the whole map
3. A **step** never calls another use case; it touches only its own noun's entities
4. Entry points never call entry points — flatten the steps, or the second flow is a reaction → event
5. A consequence not needed in the request's response = event, never a direct call

Fixed depth, always: `port → entry point → step`. Three arrows.

### The core's I/O contract

A use case has exactly three outputs, and no other:

1. **Result** — the synchronous answer, returned through the port that called it
2. **Bridge call** — an addressed request to one known outside system, mid-flow
3. **Event** — an anonymous fact recorded in the database; the core does not know who reacts

Choosing between 2 and 3: if the use case needs the answer to continue, call a bridge; if not, record an event.

```text
# BAD — hidden chain: each step calls the next, nobody sees the flow
Checkout → ValidateStock → CalculateTotal → Charge → Place

# GOOD — the entry point fans out; every failure returns where it happens
Checkout:
  stock  = ValidateStock(cart);      if stock.failed  return stock
  total  = CalculateTotal(cart);     if total.failed  return total
  charge = Payment.Charge(total);    if charge.failed return charge
  return Order.Place(cart, charge)
```

### Organization inside a layer

Inside the core, entities sit in `models/` and actions in `use_cases/`, organized by business noun (`use_cases/cart/checkout`, `use_cases/payment/charge`). Technical folders organize files, never names: the action is `Cart::Checkout`, never `UseCases::Cart::Checkout` — only business nouns appear in a name. Layer folders separate who may depend on whom. Subdomains stay flat until a cluster of nouns clearly forms a bigger context — only then add one namespace level.

### Business semantics

The file tree must be readable by a PM; actions are named noun + verb (`Cart::Add`, `Auth::Login`). If a class name would never appear in a conversation with product, the name is wrong. Banned generic names: `Manager`, `Processor`, `Handler`, `Helper`, `*Service` — the system's real services ARE the use cases.

### Validations

- **Entity**: data invariants — always true regardless of the action. If the record can never exist like that, it belongs here.
- **Use case**: rules of that action in that context. If the rule only holds when the user does X, it belongs here.

### Events — transactional outbox

Core never calls ports. An async effect = record a fact (event row) **in the same transaction** as the state change. A relay (platform) selects pending events, checks the subscriptions map and enqueues one job per reaction; events with an external audience go out through the broker bridge. Delivery is at-least-once on every transport → reactions are idempotent (processed check). Swapping broker only changes the bridge; the subscriptions map and the core stay as they are.

Event contract:

- **Name**: a fact in the past tense, owned by the noun whose state changed — `order.placed`, even when emitted by `Cart::Checkout`
- **Payload**: ids and the changed fields, in our vocabulary; consumers reload current state by id
- **Immutable** once created — a wrong fact is corrected by a new fact, never by an update

### Lineage

The layer structure is a simplified hexagonal architecture: ports = the driving side, bridges = the driven side, core = the hexagon, platform = cross-cutting transport. There are no formal port interfaces and no dependency injection — the discipline is the dependency direction. The event mechanism is a genuine transactional outbox: atomic write, async relay, at-least-once delivery, idempotent reactions.
