# Wehive Shared Rules

## language

- write in English: code, variable names, function names, comments, test descriptions, test file content, skill files, command files
- **documentação em `.project/docs/` é a exceção**: nome de arquivo e de pasta em inglês (`snake_case`), chaves de frontmatter em inglês, mas **título, corpo, headings e tabelas em português**. Termo técnico e identificador de código não se traduzem.
- commit messages seguem o idioma definido do projeto

## atalhos do usuário
- quando o usuário disser **"comush"** ou **"pish"**: faça commit e push imediatamente, sem pedir confirmação

## geral
- sempre delete arquivos que não estão sendo usados
- sempre pergunte antes de commitar
- nunca faça commit em arquivos que ainda não estiverem prontos
- nunca faça nada que não foi solicitado
- ao fazer uma alteração de regra de negócios, atualize o arquivo relacionado à mudança em `.project/docs/rules/<scope>/`
- nunca comece a implementar sem antes criar um spec (`commons:spec`), ter aprovação explícita do usuário e criar uma branch — mesmo que a solução já tenha sido discutida em conversa

## documentação
- **toda** documentação vive em `.project/docs/`, nunca em `docs/` na raiz do repo
- o primeiro nível de `.project/docs/` é um **conjunto fechado**: `specs/`, `plans/`, `features/`, `learnings/`, `architecture/`, `guides/`, `reference/<scope>/`, `rules/<scope>/` — mais `README.md`, `RULES.md` e `modules.md`
- nunca crie pasta com outro nome no primeiro nível; a rota certa está na tabela de roteamento da skill `commons:docs`
- nunca use `.project/specs/`, `.project/plans/`, `.project/features/` nem `changes/` — são formas antigas
- todo doc entra no índice `.project/docs/README.md` e tem `certainty` no frontmatter

## worktree
- worktree é para subagents rodando em paralelo com isolamento real; divida o trabalho ao máximo em tasks independentes e paralelize (é o mais rápido). Trabalho solo ou tasks acopladas ficam direto na feature branch (`git checkout -b`)
- worktree sempre em `$HOME/workspace/.worktrees/<project_name>/<task>/` — **nunca** dentro de um repo wehive.tech nem da pasta do próprio projeto
- a branch de cada worktree parte da **branch de trabalho atual**, não de `main` — a menos que o usuário peça uma base específica
- remova o worktree ao final: só quando o trabalho foi integrado (merge/PR) ou não há mudanças não commitadas; se houver trabalho não salvo, avise e mantenha
- não deixe lixo: após a limpeza, `git status` do repo e o diretório `.worktrees/` devem ficar sem sobras (`git worktree prune`)

## comentários
- **não escreva comentários que explicam o que o código faz** — código bem escrito já diz isso
- **não escreva comentários de regra de negócio ou lógica inline** — se o código precisa de comentário, está mal escrito; refatore
- comentários são aceitos apenas em: documentação de API pública (funções/classes exportadas), endpoints/swagger, workarounds para bugs externos com link para a issue
- exemplos de comentários **proibidos**:
  ```ruby
  # iterate over users and check if active   ← desnecessário
  # increment counter                         ← óbvio
  # if admin, skip validation                 ← lógica no código, não em comentário
  # TODO: fix this later                      ← não commite TODOs
  users.each do |user|
    count += 1  # increment count             ← redundante
  end
  ```
  ```python
  # check if user is active before proceeding  ← desnecessário
  if user.active:                              # user is active  ← redundante
      process(user)
  # return the result                          ← óbvio
  return result
  ```
- exemplos de comentários **permitidos**:
  ```ruby
  # Retries on 503 because the upstream billing API is flaky under load.
  # Remove once https://github.com/acme/billing/issues/42 is resolved.
  def charge(amount)
    ...
  end
  ```
  ```python
  class PaymentGateway:
      """Integrates with Stripe and handles retries on transient failures."""

      def refund(self, charge_id: str) -> dict:
          """Refund a charge. Raises RefundError if the charge is already refunded."""
  ```

## deploy k8s
- use `make deploy.staging` para buildar `linux/amd64`, pushar e aplicar com tag `dev-{user}-{hash}` (não commita kustomization.yaml)
- use `make deploy.production` apenas em emergências — verifica RBAC, pede confirmação, usa CI/CD normalmente via `make release`
- RBAC do cluster é gerenciado em `infrastructure/src/stacks/shared/kubernetes/terraform/rbac.tf` — nunca configure permissões manualmente
- owners e infra são definidos em `infrastructure/k8s/rbac/config.yml` — self-service via PR
- após criar namespaces de um novo projeto, rode `make shared.apply` no projeto `infrastructure` para propagar bindings RBAC


