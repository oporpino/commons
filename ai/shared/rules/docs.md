# Docs — onde ficam e como são indexados

Toda documentação de todo projeto WeHive vive em `.project/docs/`, cujo primeiro nível é um
**conjunto fechado**. A regra completa está em `skill:docs`.

## Localização

```
.project/docs/
├── README.md              # índice completo         (reservado)
├── RULES.md               # índice das regras R-XXX (reservado)
├── modules.md             # multi-módulo            (reservado)
├── specs/  (+ drafts/)
├── plans/
├── features/
├── learnings/
├── architecture/
├── guides/
├── reference/<scope>/
└── rules/<scope>/
```

Nunca crie pasta com outro nome no primeiro nível. Nunca crie `docs/` na raiz do repo.

## Índice

O índice completo é `.project/docs/README.md` — uma tabela por categoria, uma linha por doc:

```markdown
## Guides

| Doc | Descrição |
|---|---|
| [k8s_access](guides/k8s_access.md) | Como obter acesso ao cluster e trocar de contexto |

## Reference

| Doc | Descrição |
|---|---|
| [payment_flow](reference/payments/payment_flow.md) | Ciclo de vida de um pagamento, da criação ao webhook |
```

O `README.md` da **raiz do repo** não indexa docs individuais. Ele carrega **um** link:

```markdown
## Documentação

Toda a documentação do projeto está em [.project/docs/](.project/docs/README.md).
```

## Rules

- Um doc que não está no `.project/docs/README.md` é invisível — sempre atualize o índice
- Uma linha por doc — nunca agrupe vários docs numa linha
- A descrição é uma frase dizendo o que o leitor vai encontrar, não o título repetido
- Linhas ordenadas alfabeticamente dentro de cada seção
- O heading da seção é o nome da pasta em Title Case (`guides/` → `Guides`)
- Nunca remova uma entrada sem também remover ou mover o arquivo
- Nome de arquivo em inglês `snake_case`; conteúdo em português
