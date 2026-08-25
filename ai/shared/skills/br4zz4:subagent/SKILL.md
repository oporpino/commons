---
name: br4zz4:subagent
description: Use when executing implementation plans with independent tasks via subagents in the current session.
version: 1.0.0
---

# commons:subagent

> **TLDR**: Execute um plano despachando um subagente implementador por task, um reviewer após cada uma, e um review final de branch — sem parar entre tasks. Sequencial por padrão; modo paralelo opcional com um worktree por agente quando as tasks são realmente independentes.

---

## Quando usar

- Você tem um plano em `.project/docs/plans/`
- As tasks são majoritariamente independentes
- Quer execução contínua com revisão automática entre tasks

**Divida ao máximo:** quebre o trabalho em tasks independentes e rode-as em paralelo sempre que possível — é o caminho mais rápido. O modo paralelo é o preferido; sequencial é o fallback para tasks acopladas.

Se as tasks são fortemente acopladas (cada uma depende do output da anterior de forma não-trivial): prefira `commons:tdd` inline.

---

## Princípio central

**Subagente fresco por task + review de spec + review de qualidade + review final de branch = alta qualidade, iteração rápida.**

Por que subagentes: contexto isolado por task, sem contaminação da sessão. O controlador (você) constrói exatamente o que cada subagente precisa — nada mais.

**Execução contínua:** não pause para checar com o usuário entre tasks. Execute todas as tasks sem parar. Os únicos motivos para parar são: status `BLOCKED` que você não consegue resolver, ambiguidade genuína que impede progresso, ou todas as tasks concluídas.

---

## Processo

```
Ler plano → Pre-flight check → Por task: [implementar → review → fix se necessário] → Review final → commons:finish
```

### Antes de começar

1. Leia o plano completo em `.project/docs/plans/<filename>.md`
2. Confirme que a branch já foi criada (`git branch` — se não: `git checkout -b <type>/<desc>`)
3. Anote o SHA base: `BASE_SHA=$(git rev-parse HEAD)`
4. Crie um ledger de progresso em `tmp/progress-<planname>.md`:
   ```
   # Progress: <plan name>
   Base SHA: <sha>
   ```
5. Pre-flight: varra o plano por conflitos entre tasks ou entre tasks e constraints globais. Se encontrar, agrupe tudo em uma única pergunta ao usuário antes de começar — não interrompa no meio da execução.

### Por task

**Passo 1 — Registre o SHA antes de despachar**

```bash
TASK_BASE=$(git rev-parse HEAD)
```

**Passo 2 — Despacho o implementador**

Prompt mínimo para o subagente:

```
Você é um implementador. Sua única fonte de requisitos é o task brief abaixo.

## Onde esta task se encaixa
<uma linha sobre o contexto no plano>

## Task brief
<cole o texto completo da task do plano, incluindo arquivos, interfaces e todos os passos>

## Interfaces de tasks anteriores (se aplicável)
<funções, tipos ou contratos que tasks anteriores produziram e que esta task consome>

## Constraints globais
<copie verbatim a seção "Global constraints" do plano>

## Instruções
- Siga commons:tdd: teste primeiro, observe falhar, implemente mínimo, observe passar, refatore, commite
- Commits: uma linha, max 60 chars, sem IA
- Ao terminar, reporte APENAS: status (DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED), commits feitos, resultado dos testes (ex: 12/12 pass), e concerns se houver
- Não faça nada além do que a task pede
```

**Passo 3 — Trate o status retornado**

| Status | Ação |
|--------|------|
| `DONE` | Prossiga para review |
| `DONE_WITH_CONCERNS` | Leia os concerns; se forem de corretude/escopo, resolva antes do review; se forem observações, registre no ledger e prossiga para review |
| `NEEDS_CONTEXT` | Forneça o contexto faltante e re-despache |
| `BLOCKED` | Avalie: contexto? → re-despache. Task grande demais? → quebre. Plano errado? → escale ao usuário |

Nunca ignore um escalation nem force retry sem mudar algo.

**Passo 4 — Despache o reviewer**

Gere o diff e passe ao reviewer:

```bash
git diff $TASK_BASE..HEAD > /tmp/task-N-diff.patch
git log $TASK_BASE..HEAD --oneline >> /tmp/task-N-diff.patch
```

Prompt do reviewer:

```
Você é um code reviewer. Revise o diff da Task N.

## O que foi construído
<uma linha descrevendo o que a task deveria entregar>

## Requisitos da task
<cole o texto completo da task do plano>

## Constraints globais
<copie verbatim do plano>

## Diff
<cole o conteúdo de /tmp/task-N-diff.patch>

## Sua tarefa
Avalie em duas dimensões:

**1. Spec compliance:** a implementação entrega tudo que a task pede? Nada além?
- ✅ Spec: OK | ❌ Spec: <o que falta ou sobra>

**2. Code quality:** o código segue os padrões wehive?
- SOLID, DRY, KISS aplicados?
- Testes testam comportamento real (não mocks)?
- Commits atômicos, uma linha, max 60 chars?
- Sem comentários explicando o que o código faz?
- Aprovado | Findings: <lista com severidade Critical/Important/Minor>

Termine com: **Assessment:** Pronto para próxima task | Precisa de correções
```

**Passo 5 — Trate findings do reviewer**

| Severidade | Ação |
|------------|------|
| `Critical` | Despache fix subagente imediatamente; re-review depois |
| `Important` | Despache fix subagente; re-review depois |
| `Minor` | Registre no ledger; triage no review final |
| `⚠️ Cannot verify` | Você verifica manualmente usando o plano e contexto cross-task; se for gap real, trate como Critical/Important |

Findings fora do padrão do projeto (SOLID, naming, layer boundaries): aplique `commons:review-receive` — sempre aborde nesta PR ou abra uma PR em sequência.

**Fix subagente** — prompt mínimo:

```
Você é um fixer. Corrija os findings abaixo sem alterar nada além do necessário.

## Findings a corrigir
<lista de findings Critical/Important com arquivo e linha>

## Constraints
- Re-execute os testes que cobrem o código alterado após cada correção
- Reporte: o que foi corrigido, comando de teste rodado, resultado
- Nada além dos findings — sem refatorações extras
```

Após o fix, re-despache o reviewer com o diff atualizado.

**Passo 6 — Registre no ledger**

```
Task N: completa (commits <base7>..<head7>, review limpo)
```

---

### Depois de todas as tasks

**Review final de branch**

Despache um reviewer com o diff completo da branch:

```bash
MERGE_BASE=$(git merge-base main HEAD)
git diff $MERGE_BASE..HEAD > /tmp/final-branch-diff.patch
git log $MERGE_BASE..HEAD --oneline >> /tmp/final-branch-diff.patch
```

Prompt:

```
Você é um code reviewer fazendo review final de branch antes do merge.

## O que foi construído
<descrição do objetivo do plano>

## Spec
<caminho para .project/docs/specs/<arquivo>.md ou cole o conteúdo>

## Diff completo da branch
<conteúdo de /tmp/final-branch-diff.patch>

## Minors acumulados
<lista de Minor findings registrados no ledger>

Avalie: spec coberta integralmente? Qualidade geral? Algum Minor deve ser promovido a Important antes do merge?

Assessment: Pronto para merge | Precisa de correções
```

Se o review final tiver findings: despache **um único fix subagente** com a lista completa — não um por finding.

---

### Finalize

Após review final limpo, invoque `commons:finish`.

---

## Modo paralelo (preferido)

**Divida o trabalho ao máximo em tasks independentes e rode-as em paralelo** — é assim que o trabalho flui mais rápido. Só caia no sequencial quando as tasks são acopladas de verdade: uma consome o output da outra, ou **duas tocam os mesmos arquivos**. Na dúvida sobre conflito de arquivos, sequencial para aquele par; tudo que for independente continua em paralelo.

### Quando vale

- Tasks independentes que rodam sozinhas (ex: 3 endpoints isolados, 3 arquivos de teste sem relação, módulos que não se cruzam)
- Sempre que der para paralelizar sem conflito de arquivos — o overhead de worktree compensa

### Isolamento por worktree

Cada agente paralelo trabalha no **seu próprio worktree**, sempre sob `$HOME/workspace/.worktrees/<project>/<task>/` — nunca dentro do repo ou da pasta do projeto (regra de worktree do wehive).

O worktree parte **da branch de trabalho atual** (onde o plano está sendo executado), não de `main` — a menos que o usuário peça uma base específica:

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel)")
WORK_BRANCH=$(git rev-parse --abbrev-ref HEAD)
WT_ROOT="$HOME/workspace/.worktrees/$PROJECT"
mkdir -p "$WT_ROOT"

# uma vez por task independente — branch da task parte da branch de trabalho:
git worktree add "$WT_ROOT/task-N" -b "$WORK_BRANCH-task-N" "$WORK_BRANCH"
```

Despache um implementador por worktree, **todos no mesmo turno** (chamadas de subagente em paralelo). O prompt do implementador é o mesmo do modo sequencial, mais uma linha:

```
## Workspace
Trabalhe em: $HOME/workspace/.worktrees/<project>/task-N — todo comando git roda lá.
```

### Integrar e revisar

Quando os agentes retornam, integre um por vez na **branch de trabalho** (rebase/merge de cada branch de task de volta na branch de onde partiram), rodando o review de cada task como no modo sequencial. Conflito de merge = as tasks não eram independentes; resolva e registre a lição.

### Cleanup obrigatório

Após integrar cada task (ou ao final), remova o worktree — só quando o trabalho já está na branch de trabalho ou não há mudanças não commitadas:

```bash
git worktree remove "$WT_ROOT/task-N"
git worktree prune
```

Se um worktree tem trabalho não commitado, **não remova** — avise e mantenha. `commons:finish` também faz essa varredura ao final.

---

## Ledger de progresso

O ledger vive em `tmp/progress-<planname>.md` (gitignored — adicione ao `.gitignore` local se necessário, ou mantenha como scratch).

Formato:

```markdown
# Progress: <plan name>
Base SHA: <sha>

Task 1: completa (commits abc1234..def5678, review limpo)
Task 2: completa (commits def5678..ghi9012, review limpo — minor: magic number linha 42)
Task 3: in_progress
```

Após compaction de contexto: leia o ledger + `git log` para se orientar. Não re-despache tasks já marcadas como completas.

---

## Red flags

**Nunca:**
- Começar na `main` sem consentimento explícito do usuário
- Criar worktree fora de `$HOME/workspace/.worktrees/<project>/` — nunca dentro do repo ou da pasta do projeto
- Deixar worktree para trás: remova ao integrar (`git worktree remove` + `git worktree prune`)
- Rodar em paralelo tasks que tocam os mesmos arquivos — só paraleliza o que é realmente independente
- Pular o review da task
- Fazer o subagente ler o plano inteiro — passe só o texto da task
- Aceitar "quase certo" em spec compliance — se o reviewer encontrou gaps, não está pronto
- Pular o re-review após um fix
- Pré-julgar findings para o reviewer ("não marque isso como Critical")
- Re-despachar uma task que o ledger já marca como completa

**Se o subagente perguntar:**
- Responda completo antes de deixá-lo prosseguir

**Se o reviewer encontrar issues:**
- Fix subagente → re-review → só então marca completa

---

## Regras wehive preservadas

- Sequencial usa branch normal (`git checkout -b`); paralelo usa worktree em `$HOME/workspace/.worktrees/<project>/`, sempre removido ao integrar
- Commits: uma linha, max 60 chars, sem IA
- TDD em cada task (via `commons:tdd`)
- Ao final, `commons:finish` decide PR vs merge vs manter
