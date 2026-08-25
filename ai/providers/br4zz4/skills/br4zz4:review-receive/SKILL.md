---
name: review-receive
description: Use when receiving code review feedback, before implementing suggestions.
version: 1.0.0
---

# commons:review-receive

> **TLDR**: Technical evaluation first, implementation second. Verify before implementing. Ask before assuming. No performative agreement.

---

## Core principle

Code review requires technical evaluation, not emotional performance.

Verify before implementing. Ask before assuming. Technical correctness over social comfort.

---

## Response pattern

```
1. READ:      Complete feedback without reacting
2. UNDERSTAND: Restate each item in own words (or ask)
3. VERIFY:    Check against codebase reality
4. EVALUATE:  Technically sound for THIS codebase?
5. RESPOND:   Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

---

## Forbidden responses

Never say:
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!"
- "Thanks for catching that!"
- "Let me implement that now" (before verification)
- Any gratitude expression

Instead:
- Restate the technical requirement
- Ask clarifying questions if unclear
- Push back with technical reasoning if wrong
- Just start working (actions over words)

When feedback IS correct:
```
✅ "Fixed. [brief description of what changed]"
✅ "Good catch — [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the diff]
```

---

## Handling unclear feedback

If ANY item is unclear: stop, do not implement anything yet, ask for clarification.

Items may be related. Partial understanding = wrong implementation.

```
❌ WRONG: Implement items 1,2,3 now, ask about 4,5 later
✅ RIGHT: "Entendi os itens 1,2,3. Preciso de esclarecimento nos itens 4 e 5 antes de implementar."
```

---

## Handling out-of-pattern findings

When the reviewer flags code that violates project patterns (SOLID, DRY, naming conventions, layer boundaries, etc.), even if it is not a bug:

> "O reviewer encontrou `[issue]` — está fora do padrão do projeto. É fortemente recomendável corrigir. Prefere:
>
> 1. Corrigir neste PR (antes de mergear)
> 2. Abrir um PR em sequência com o refactor (recomendado se o escopo for grande)
>
> Em ambos os casos, o refactor deve acontecer — a questão é quando."

Do not skip or defer without acknowledgment from the user.

---

## Evaluating external reviewer suggestions

Before implementing any suggestion from an external reviewer:

1. Is it technically correct for THIS codebase?
2. Does it break existing functionality?
3. Is there a reason for the current implementation?
4. Does the reviewer have full context?
5. Does it conflict with prior architectural decisions?

If the suggestion seems wrong: push back with technical reasoning.

If you can't verify: "Não consigo verificar isso sem `[X]`. Queres que eu investigue, pergunte, ou prossiga?"

---

## YAGNI check

When a reviewer suggests adding a feature, endpoint, or abstraction:

```bash
grep -r "suggested_thing" .
```

If unused: "Não encontrei uso disso. Remover (YAGNI)?"
If used: implement properly.

---

## Implementation order

For multi-item feedback:

1. Clarify anything unclear FIRST
2. Then implement:
   - Blocking issues (crashes, security)
   - Simple fixes (typos, missing imports)
   - Complex fixes (logic, refactoring)
3. Test each fix individually
4. Verify no regressions

---

## When to push back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI
- Technically incorrect for this stack
- Conflicts with prior architectural decisions

How to push back: use technical reasoning, reference tests or code, involve the user if it is architectural.

---

## If you pushed back and were wrong

```
✅ "Você estava certo — verifiquei [X] e de fato [Y]. Implementando agora."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

---

## Rules

- Verify against codebase before implementing any suggestion
- Test each fix individually before moving to the next
- Never implement unclear feedback without asking first
- Out-of-pattern findings must be addressed in this PR or the next — never silently deferred
- Apply `commons:verify` after implementing all fixes
