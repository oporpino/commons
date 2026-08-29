---
name: br4zz4:docs
description: Use when documenting business rules or learnings.
version: 2.2.0
---

# commons:docs

> **TLDR**: Toda documentação vive em `.project/docs/`, cujo primeiro nível é um **conjunto fechado** de 8 pastas. Use a tabela de roteamento para decidir o destino — primeira resposta afirmativa vence. Nome de arquivo em inglês, conteúdo em português.

## Context

Antes de escrever qualquer doc, leia os docs existentes para entender convenções e evitar duplicação:

- **Docs do projeto**: `.project/docs/` no diretório atual
- **Docs do commons**: `.project/docs/` no repo commons (`ibft-corp/commons`) — guides, architecture e patterns que valem para todos os projetos br4zz4

---

## Layout — conjunto fechado

```
<project-root>/.project/docs/
├── README.md              # índice de toda a documentação      (reservado)
├── RULES.md               # índice das regras de negócio R-XXX  (reservado)
├── modules.md             # convenção de módulos, multi-módulo  (reservado)
│
├── specs/                 # mudanças planejadas ou executadas
│   └── drafts/            # specs aprovadas mas não iniciadas
├── plans/                 # passo-a-passo de implementação de uma spec
├── features/              # user stories + critérios de aceite (Gherkin)
├── learnings/             # aprendizados retrospectivos de bug ou decisão
├── architecture/          # decisões arquiteturais e suas consequências
├── guides/                # how-to operacional (setup, deploy, acesso, debug)
├── reference/<scope>/     # como o sistema é: fluxos, APIs, contratos, modelos
└── rules/<scope>/         # regra de negócio em Given/When/Then
```

**O primeiro nível é fechado.** Exatamente estas 8 pastas e 3 arquivos. `<scope>` (domínio
de negócio: `billing`, `membership`, `habits`, `payments`, …) existe **apenas** dentro de
`reference/` e `rules/`.

> Se você está criando uma pasta em `.project/docs/` cujo nome não é `specs`, `plans`,
> `features`, `learnings`, `architecture`, `guides`, `reference` ou `rules` — pare.
> A resposta está na tabela de roteamento, não numa pasta nova.

---

## Tabela de roteamento

Avalie de cima para baixo. **A primeira resposta afirmativa decide** — não continue lendo.

| # | Pergunta | Destino |
|---|---|---|
| 1 | É instrução para agente de IA (`CLAUDE.md`, `AGENTS.md`, rules de agente)? | **Não é doc.** → `CLAUDE.md` na raiz do repo, ou `.project/ai/rules/` |
| 2 | É asset não-markdown (`.json`, `.html`, `.js`, `.png`, `.txt`)? | `<categoria>/assets/` |
| 3 | Descreve uma mudança — planejada ou já executada — com contexto e objetivos? | `specs/` |
| 4 | É o passo-a-passo de implementação de uma spec existente? | `plans/` |
| 5 | É user story ou critério de aceite de produto? | `features/` |
| 6 | É um aprendizado retrospectivo de um bug, incidente ou decisão? | `learnings/` |
| 7 | É uma regra de negócio expressável em Given/When/Then? | `rules/<scope>/` |
| 8 | Registra uma decisão arquitetural e suas consequências? | `architecture/` |
| 9 | Ensina o leitor a executar algo (setup, deploy, acesso, troubleshooting)? | `guides/` |
| 10 | Descreve como o sistema é ou funciona (fluxo, API, contrato, modelo de dados)? | `reference/<scope>/` |

Se nenhuma bateu, provavelmente não é documentação. Não crie pasta nova — decida entre
`reference/` e `guides/`.

### Desempates frequentes

| Caso | Rota | Por quê |
|---|---|---|
`payment_flow.md` — descreve o ciclo de vida de um pagamento | `reference/payments/` | descreve como funciona, não ensina a fazer |
`habits/implementation_plan.md` | `plans/` | pergunta 4 vence pergunta 10 |
`getting_started.md` | `guides/` | ensina a executar |
`architecture-abstraction.md` | `architecture/` | decisão + consequência |
`i18n-error-messages.md` — comportamento existente da API | `reference/api/` | é referência, não regra Given/When/Then |
`apolo_membership_selects_newest_paid.md` | `rules/membership/` | expressável em Given/When/Then |
`changes/*.md` — registro histórico de mudança | `specs/` | é spec com outro nome |
`dev_tooling/*`, `patterns/*` | `guides/` | ambos são how-to |
`habit-notification-plan.md` — descreve fluxo e campos, não passos | `reference/` | **rote pelo conteúdo, nunca pelo sufixo do nome** — a pergunta 4 não dispara |
`observability_resilience.md` — escrito como ADR (Context/Decision/Alternatives) | `specs/` | a pergunta 3 vem antes da 8 e casa; preserve a estrutura de decisão dentro do template de spec |
`invoice-payment-flow.md` — tem regras dentro, mas é fluxo ponta a ponta | `reference/` | não cabe num Given/When/Then; Q7 falha, Q10 vence |
`.project/ai/rules/architecture.md` — prescritivo para quem escreve código | **permanece** | pergunta 1; é importado por `.project/ai/main.md`, mover quebra o contexto do agente |
`.infra/terraform/README.md`, `src/**/README.md` com how-to | `guides/` | doc colocado junto do código de infra ainda é doc |
`apps/*/README.md` com 3–8 linhas de "como testar X" | **permanece** | README convencional de módulo; migrar criaria guides quase vazios |
`README.md` de raiz com 200+ linhas de doc operacional | dividido em `guides/` + `reference/` | a raiz fica com intro + **um** link |
`spec/**` (RSpec), `k8s/base/specs/*.yaml` (kustomize) | **não é doc** | `specs/` em outro sentido |
`.github/PULL_REQUEST_TEMPLATE.md` | **não é doc** | mecanismo do GitHub |
`.project/specs/template.md` | **remova** | o template vive nesta skill; uma segunda cópia cria duas fontes que divergem |

### Doc que já tem `R-XXX` nunca é rebaixado

Se um doc já carrega um ID de regra registrado num `RULES.md` existente, ele vai para
`rules/<scope>/` — mesmo que você julgue que caberia melhor em `reference/`. Rebaixá-lo
destrói um ID que outros docs, testes e commits podem referenciar.

Quando **não** há ID prévio, a linha divisória é:

> O doc afirma um resultado condicional ("dado X, então Y"), ou descreve um mecanismo?
> Afirma resultado → `rules/`. Descreve mecanismo → `reference/`.

### Doc que mistura regra e descrição: dissolva

Um arquivo com RN01–RN08 em Dado/Quando/Então **mais** models e state machine vira N
arquivos em `rules/<scope>/` (um por regra, com o ID original anotado no corpo) + o corpo
descritivo em `reference/<scope>/`. Deixar tudo em `reference/` faria o `RULES.md` apontar
para reference, o que ele não pode.

---

## Onde procurar doc órfão

Um inventário que só olha `docs/` e `.project/docs/` está incompleto. Antes de concluir que
não há nada a migrar, verifique:

| Lugar | O que costuma estar lá |
|---|---|
`rfcs/`, `adr/`, `decisions/` | specs e decisões arquiteturais com outro nome |
`.md` tracked na raiz do repo | `API.md`, `SUMMARY.md`, `CLASS_DIAGRAM.md`, `pr.md`, `how-to-release.md` |
junto do código | `.infra/**/README.md`, `src/**/README.md`, `INSTALL.md`, `make/.MAKEFILE.md` |
**dentro de `modules/`** | em monorepo, `modules/*/docs/` costuma ter regra, learning e spec |

```bash
git ls-files -- '*.md' | grep -v '^\.project/' \
  | grep -viE '(^|/)(readme|claude|agents|contributing|changelog|license)\.md$'
```

---

## Nomes de arquivo

**Nome em inglês, conteúdo em português.** Sempre `snake_case`, sem acento, sem espaço,
sem maiúscula.

| Categoria | Padrão | Exemplo |
|---|---|---|
`specs/`, `plans/` | `YYYYMMDDHHMMSS_short_name.md` | `20260709170553_notify_trg_club_on_expiry.md` |
`features/` | `USER-XXX-short_name.md` | `USER-007-kommo_adapter.md` |
`rules/<scope>/` | `short_name.md` | `rules/membership/renewal_requires_payment.md` |
`learnings/` | `<scope>_short_name.md` | `learnings/billing_pix_expiration_race.md` |
demais | `short_name.md` | `guides/k8s_access.md` |

### Timestamp: redate só quando o nome não tem prefixo válido

Arquivo que já tem prefixo `YYYYMMDDHHMMSS` **mantém o nome**, mesmo que o git discorde da
data. O timestamp no nome é a hora de autoria, que é legítima; o commit é quando o arquivo
chegou ao repo — informação diferente, degradada por rename e squash.

Redatar arquivo já conforme causa dano real:

| Situação | O que acontece |
|---|---|
vários arquivos adicionados no mesmo commit | todos colapsam num timestamp único — colisão criada pela própria regra |
squash-merge | o primeiro commit diverge do nome sem que isso signifique nada |
diferença de horas ou semanas | churn de histórico sem ganho de informação |

Quando você **precisa** derivar do git (nome sem prefixo, tipo `00001_poc_basic_proxy.md`),
o `--follow` é obrigatório:

```bash
git log --follow --format=%ad --date=format:%Y%m%d%H%M%S -- <file> | tail -1
```

> Sem `--follow` o comando devolve o commit de **rename**, não o de criação. `--diff-filter=A`
> acha onde o *path* foi adicionado, e um rename adiciona o path novo. Qualquer repo que já
> renomeou `changes/` → `specs/` devolve o commit do rename para todos os arquivos.

Rode contra o path **antigo em HEAD** — no path novo, se o move só está staged, retorna vazio.

Se dois arquivos legitimamente nascerem no mesmo commit, mantenha o timestamp igual e conte
com o `short_name` para diferenciar. Não invente minuto para desempatar.

`updated:` é a data do **último** commit que tocou o arquivo, nunca a data de hoje:

```bash
git log -1 --format=%ad --date=short -- <file>
```

---

## Idioma

| O que | Idioma |
|---|---|
Nome de arquivo e de pasta | **inglês**, `snake_case` |
Chaves de frontmatter | **inglês** |
Título, corpo, headings, tabelas | **português** |

Termo técnico e identificador de código não se traduzem — só a prosa. Commits seguem a
regra global: uma linha, ≤60 chars.

---

## Frontmatter

Todo doc tem frontmatter YAML, e **`certainty` é obrigatório em todas as categorias**.
Ele separa o que estava registrado do que foi reconstruído lendo código:

| `certainty` | Significado |
|---|---|
`high` | conteúdo veio do documento original ou de código verificado |
`medium` | parcialmente reconstruído a partir do código |
`low` | majoritariamente inferido, **ou** o doc e o código se contradizem e a decisão é humana |

`low` é uma saída legítima, não uma falha. Quando o doc afirma um comportamento que o código
não tem, documente o **comportamento verificado no código**, registre a divergência específica
em `## Restrições`, e marque `low` — qual dos dois está certo é chamada de produto, não sua.

---

## Conteúdo: verifique antes de registrar

Conteúdo reconstruído errado é pior que conteúdo ausente. Três regras:

**`status:` se verifica contra o código, não se copia do doc.** Spec marcada `proposed` ou
`in_progress` cuja entrega já está em produção é o caso comum, não a exceção. Leia o código,
corrija o `status`, e registre a divergência numa seção `## Notas` do próprio doc.

**Nunca marque `superseded` sem confirmar que o sucessor foi implementado.** Se a spec que
substitui esta ainda é plano, marcar `superseded` registra como fato algo que não aconteceu.
Escreva um bloco de sucessão apontando para ela, com a ressalva de que a atual vale até lá.

**Afirmação do original que o código contradiz: remova, não propague.** Contrato de API com
path errado, diagrama de classe com drift de schema, namespace com um hífen em vez de dois —
corrija contra o código. Não carregue a afirmação falsa para o doc novo.

Seção sem informação no original: `— (não registrado no doc original)`. Nunca invente.

---

## Templates

### `rules/<scope>/`

```markdown
---
id: R-XXX
title: <título em português>
scope: <billing | membership | auth | ...>
certainty: high | medium | low
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# R-XXX — <Título>

> **TLDR**: uma frase descrevendo a regra e seu propósito.

## Given / When / Then

**Dado** [estado do sistema ou pré-condição]
**Quando** [evento ou ação que dispara a regra]
**Então** [resultado esperado ou comportamento do sistema]

## Tabela de decisão

> Use só quando a regra tem múltiplas condições. Remova esta seção para regras simples.

| Condição A | Condição B | Resultado |
|---|---|---|
| true | true | resultado 1 |
| true | false | resultado 2 |

## Restrições

- Nunca [o que é proibido]
- Sempre [o que é obrigatório]

## Teste vinculado

`test/caminho_test.rb` — "descrição do teste"
```

`R-XXX` é sequencial **por projeto** — consulte `.project/docs/RULES.md` para o último ID.
Sem teste: `(sem teste ainda)`.

### `learnings/`

```markdown
---
title: <título em português>
scope: <habits | billing | auth | ...>
date: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

## O que aconteceu

<Um parágrafo com o sintoma do ponto de vista do usuário ou do comportamento do sistema>

## Causa raiz

<Motivo — regra de negócio, lógica, decisão de design ou comportamento técnico relevante>

## Correção

<O que foi mudado ou decidido e por quê>

## Como evitar

<Regra ou padrão que o time deve seguir para não repetir>
```

**Foco principal: regra de negócio.** Explique o comportamento do ponto de vista do
produto — o que aconteceu para o usuário, por que estava errado, como evitar. Detalhe
técnico é secundário. Evite jargão de código (nomes de classes, métodos, queries) no
título e nos parágrafos principais.

Learnings **não** entram em `RULES.md` — são separados das regras de negócio.

### `specs/`

```markdown
---
title: <título em português>
status: draft | proposed | in_progress | done | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: "@<handle>"
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase — o que muda e por quê.

## Contexto
## Objetivos
## Fora de escopo
## Mudanças
## Como verificar
## Documentação
```

Seção sem informação no original: `— (não registrado na spec original)`.

`draft` é o status de spec aprovada mas não iniciada, que vive em `specs/drafts/`. Ao começar
a implementação, mova para `specs/` e troque para `in_progress` — nunca implemente a partir de
um draft sem mover primeiro. `completed` não existe no enum; mapeie para `done`.

### `plans/`

```markdown
---
title: <título em português>
spec: specs/<arquivo>.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase.

## Fases
## Verificação
```

`spec:` aponta para a spec correspondente, ou `null` se não houver.

### `features/`

```markdown
---
id: USER-XXX
title: <título em português>
scope: <domínio>
created: YYYY-MM-DD
updated: YYYY-MM-DD
certainty: high | medium | low
---

# USER-XXX — <Título>

> **TLDR**: uma frase.

## História

Como <persona>, quero <ação>, para <benefício>.

## Critérios de aceite

```gherkin
Cenário: ...
  Dado ...
  Quando ...
  Então ...
```
```

Não crie índice local (`features/INDEX.md` e afins) — o índice é único e fica em
`.project/docs/README.md`. Nome em maiúscula viola a regra de nomes, e um índice por
categoria cria fontes que divergem.

Se um `INDEX.md` já existe e contém mais do que índice — roadmap, grafo de dependências,
glossário de domínio — o problema é o **nome**, não a existência. Renomeie para o que ele
é (`roadmap.md`), preservando o conteúdo.

O template acima é **estrutura mínima**, não camisa de força: quando a feature real tem
modelo de dados, endpoints e RBAC, adicione o frontmatter, o TLDR, a `## História` e
converta os critérios em Gherkin de verdade — e preserve as seções de domínio.

### `reference/<scope>/`

```markdown
---
title: <título em português>
scope: <domínio>
updated: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase.

## Visão geral
## Fluxo
## Contratos
## Referências
```

Use bloco ```mermaid``` na seção Fluxo quando o fluxo tiver mais de dois saltos.

### `guides/` e `architecture/`

```markdown
---
title: <título em português>
updated: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase.

## Pré-requisitos     (guides)
## Passos             (guides)
## Troubleshooting    (guides)

## Contexto           (architecture)
## Decisão            (architecture)
## Consequências      (architecture)
```

---

## Índices

Dois índices, com papéis distintos:

| Arquivo | Papel |
|---|---|
`.project/docs/README.md` | índice completo — uma tabela por categoria, uma linha por doc, descrição de uma frase |
`.project/docs/RULES.md` | só as regras de negócio |

Formato do `RULES.md`:

```markdown
| ID | Título | Scope | Certainty | Arquivo |
|---|---|---|---|---|
| R-001 | Título da regra | membership | high | [arquivo.md](rules/membership/arquivo.md) |
```

Linhas ordenadas por ID crescente. Crie `RULES.md` se não existir.

O `README.md` da **raiz do repo** não indexa docs individuais — carrega **um** link para
`.project/docs/README.md`.

---

## Como NÃO deve ficar

| ❌ Errado | ✅ Certo |
|---|---|
`docs/` na raiz do repo | `.project/docs/` |
`.project/specs/` | `.project/docs/specs/` |
`.project/plans/` | `.project/docs/plans/` |
`.project/features/` | `.project/docs/features/` |
`.project/rules/` | `.project/ai/rules/` (não é doc) |
`docs/specs/` | `.project/docs/specs/` |
`.project/changes/`, `.project/docs/changes/`, `.project/ai/changes/` | `.project/docs/specs/` |
`.project/docs/superpowers/`, `.project/docs/prototype/` | pasta do conjunto fechado |
`.project/docs/<qualquer-nome-livre>/` | uma das 8 pastas fechadas |
`.project/docs/dev_tooling/`, `.project/docs/patterns/` | `.project/docs/guides/` |
`.module/docs/`, `.module/specs/` | `.project/docs/` na raiz do repo |
`.project/docs/CLAUDE.md` | `CLAUDE.md` na raiz do repo |
`rfcs/` na raiz do repo | `.project/docs/specs/` (ou `architecture/`, se for decisão) |
`API.md`, `SUMMARY.md`, `CLASS_DIAGRAM.md`, `pr.md` na raiz | rote pela tabela |
`modules/<m>/docs/`, `modules/<m>/specs/` | `.project/docs/` na raiz do repo |
`.infra/**/README.md`, `src/**/README.md` com how-to | `.project/docs/guides/` |
`README.md` de raiz com 200+ linhas de doc | dividido em `guides/` + `reference/` |
`features/INDEX.md` ou qualquer índice local | índice único em `.project/docs/README.md` |
`.project/specs/template.md` no repo | o template vive nesta skill |
`status` copiado do doc sem conferir o código | `status` verificado contra o código |
`superseded` sem o sucessor implementado | bloco de sucessão + ressalva |
`updated:` com a data de hoje | data do último commit que tocou o arquivo |
redatar arquivo que já tem prefixo `YYYYMMDDHHMMSS` | manter o nome |
`git log --diff-filter=A` para derivar timestamp | `git log --follow` |
doc com `R-XXX` movido para `reference/` | ID registrado nunca é rebaixado |
`Ficha Unificada.dc.html`, `RULES-v2.MD` | `snake_case` sem espaço/acento/maiúscula |
título e corpo em inglês | conteúdo em português |
nome de arquivo em português | nome em inglês |
doc fora do `.project/docs/README.md` | todo doc indexado |
doc sem `certainty` no frontmatter | `certainty` obrigatório em toda categoria |

---

## Rules

- Aplique a tabela de roteamento **antes** de criar o arquivo — o destino é mecânico, não é julgamento
- Nunca crie pasta nova no primeiro nível de `.project/docs/`
- Um arquivo por regra e por learning — nunca combine dois no mesmo arquivo
- TLDR é obrigatório — uma frase, logo após o título
- Em `rules/`, Given/When/Then é obrigatório; Tabela de decisão é opcional
- Sempre linke o teste que valida a regra; se não houver, `(sem teste ainda)`
- Crie o subdiretório de scope antes de escrever o arquivo
- Quando uma regra de negócio muda no código, atualize o doc e ajuste `updated:`
- Depois de criar ou atualizar qualquer doc, atualize `.project/docs/README.md`
- Se o aprendizado revelar padrão cross-project, crie ou atualize também `.commons/ai/shared/rules/<topic>.md`
- Ao inventariar um repo, **inventarie tudo** — nunca trate uma lista recebida como exaustiva
- Verifique `status` e afirmações contra o código antes de registrar; `certainty` diz o quanto você conferiu

### Ao mover docs em lote

**`git add -- <lista>` aborta a invocação inteira se qualquer pathspec não casar.** Passar um
diretório que ficou vazio depois dos `git mv` faz o add falhar por completo: nada é staged e o
commit sai incompleto, em silêncio. Confira sempre antes de commitar:

```bash
git diff --cached --name-status
```

**Rode a conferência final depois do `git pull`/rebase, não antes.** Um commit concorrente pode
recriar pasta proibida sem gerar conflito — o arquivo novo não colide, só reaparece. E confira
contra o **remoto**, não contra o working tree: um `rmdir` local limpa o diretório vazio e dá
falso positivo enquanto o arquivo do commit concorrente segue rastreado.

```bash
git ls-tree -r origin/main --name-only | grep '^docs/'   # deve ser vazio
```

**`git mv` + reescrita completa no mesmo commit derruba a detecção de rename.** A similaridade
cai abaixo do limiar padrão de 50% e o git registra add+delete. Nada de histórico se perde —
só precisa de limiar menor para traçar:

```bash
git log --follow -M20% -- <file>
```

Se preservar o `R` no limiar padrão importar, faça dois commits: o move puro primeiro, a
reescrita depois.
