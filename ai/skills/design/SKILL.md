---
name: skill:design
description: Apply when writing or reviewing code. Enforces SOLID, DRY, KISS, and Clean Code principles. Work as a senior engineer — less code, more elegance, zero repetition.
version: 1.0.0
---

# Design Skill

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
