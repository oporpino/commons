# commons
Commons scripts and rules of projects

## WeHive Environment Setup

### Pré-requisitos

- **[GitHub CLI (`gh`)](https://cli.github.com)** — instalado e autenticado com acesso à org `ibft-corp`

```bash
brew install gh
gh auth login
```

### Setup

```bash
gh api repos/ibft-corp/bootstrap/contents/environment/init.sh --jq '.content' | base64 -d | bash
```

> Repositório de bootstrap: [ibft-corp/bootstrap](https://github.com/ibft-corp/bootstrap)

### Desinstalar

```bash
gh api repos/ibft-corp/bootstrap/contents/environment/init.sh --jq '.content' | base64 -d | bash -s -- --undo
```

### Comandos úteis

| Comando | Descrição |
|---|---|
| `make setup` | Inicializa ou reconfigura o projeto (`.env`, asdf) |
| `make run.server` | Roda o projeto |
| `make git.branches.clean` | Remove branches locais já mergeadas |

## Documentação

Toda a documentação deste repo está em [.project/docs/](.project/docs/README.md).
