## arquitetura

- esta é uma infraestrutura Terraform hierárquica, multi-runtime e multi-provider
- tudo é organizado em três conceitos principais: stacks (instâncias deployáveis), modules (componentes reutilizáveis) e frameworks (abstrações de runtime/provider)
- use o diretório `src/` para todo código Terraform com subdiretórios `stacks/` e `modules/`

## estrutura de diretórios

- organize em `src/` com `stacks/` e `modules/`
- stacks: instâncias deployáveis em `src/stacks/{platform,shared,contexts}`
- stacks: platform = foundation (backend, network), shared = recursos cross-context (kubernetes, messagebroker), contexts = applications
- stacks: dentro de cada stack `terraform/`, ter apenas `main.tf` na raiz
- stacks: organizar outros arquivos em subdiretórios: `core/` (backend, versions, variables, data, outputs) e `resources/` (definições de recursos)
- stacks: dentro de `resources/`, organizar por app quando context tiver múltiplos apps
- modules: componentes reutilizáveis organizados por tipo de abstração em `src/modules/{providers,runtimes,direct}/`
- modules: `providers/` = módulos multi-provider (database: digitalocean/aws-rds, cache: container/managed)
- modules: `runtimes/` = módulos multi-runtime (n8n: app-platform/kubernetes)
- modules: `direct/` = módulos de implementação direta, sem abstração (cloudflare-dns, network)
- modules: estrutura interna: apenas `main.tf` na raiz, `core/` com `variables.tf` e `outputs.tf`, `engines/<engine-name>/` em subdirs
- IMPORTANTE: sempre criar module quando houver repetição de código terraform
- priorizar DRY — modules evitam duplicação
- estado: usar hierarquia `stacks/{camada}/{componente}`

## frameworks

- apps devem nascer multi-runtime (suportar app-platform, kubernetes, etc)
- componentes de infraestrutura devem ser multi-provider quando aplicável
- use `count` com seleção de provider/runtime: `count = var.provider_type == "digitalocean" ? 1 : 0`
- normalize outputs usando o padrão `locals.active`
- usar `count` para alternar providers (`try(module[0], null)`)

## runtimes

- tudo deve nascer multi-runtime (app-platform, kubernetes, etc)
- usar `coalesce` para cascata global → project → app
- global define padrão, project sobrescreve global, app sobrescreve project
- módulos devem ter interface idêntica independente do runtime

## cascata de variáveis

- implemente hierarquia de três níveis: global → project → app
- lógica de resolução em `data.tf`: `local.app_runtime = coalesce(var.mkt_onion_runtime, var.mkt_runtime, var.runtime)`
- estrutura do `.env`: `TF_VAR_runtime` (global), `TF_VAR_mkt_runtime` (project), `TF_VAR_mkt_onion_runtime` (app)
- string vazia em prioridade menor significa usar prioridade maior
- exemplo: runtime global="app-platform", project mkt pode sobrescrever, app onion pode sobrescrever mkt

## nomenclatura hierárquica

- tudo segue o padrão de escopo aninhado: global → project → app → framework
- variáveis: nível global `${attribute}`, nível project `${project}_${attribute}`, nível app `${project}_${app}_${attribute}`
- recursos: usar `${projeto}-${tipo}` com hifens (ex: `mkt-database`, `onion-app`)
- outputs: seguir padrão `${recurso}_${atributo}` (ex: `database_host`, `onion_app_url`)
- makefile: usar hierarquia `<project>.<app>.<action>` (ex: `mkt.onion.deploy`)
- tags: incluir escopo completo do projeto em todos os recursos

## scripts

- organizar em `bin/helpers/` e `bin/stacks/{scope}/{component}/{runtime}/`
- helpers para utilitários gerais (bootstrap, credentials, passwords)
- todas as rotinas devem estar em scripts no `bin/`, nunca inline no makefile
- usar `set -a; source .env; set +a` para carregar variáveis
- validar variáveis obrigatórias antes de apply
- makefile: apenas chamar scripts, nunca ter lógica inline

## variáveis

- sempre configurar de forma global no `.env`
- sempre atualizar `.env.example` quando adicionar nova variável
- usar prefixo `TF_VAR_` para o Terraform ler automaticamente do ambiente

## backend

- todos os states devem apontar para Spaces do DigitalOcean (S3-compatible)
- usar hierarquia de keys para organizar states por contexto

## workflow de deploy

- **SEMPRE** use make targets para operações Terraform (apply, plan, destroy, etc)
- **NUNCA** rode comandos terraform diretamente para operações
- comandos corretos: `make stateless.mkt.n8n.bootstrap.apply`, `make shared.messagebroker.status`
- comandos incorretos: `terraform apply`, `bin/tf apply`, `cd src/stacks/.../terraform && terraform apply`
- make targets gerenciam variáveis de ambiente, state e sequenciamento correto
- sempre rode `make plan` antes de `make apply` para revisar mudanças
- ordem de apply deve seguir hierarquia: platform → shared → stateful → stateless
- IMPORTANTE: antes de apply, mostrar runtimes/providers sendo usados e pedir confirmação

## comandos terraform

- **OPERAÇÕES** — SEMPRE use make targets (apply, plan, destroy, taint, etc)
- **INVESTIGAÇÃO** — use wrapper `wehive terraform` para debugging/inspeção
- `wehive terraform` carrega `.env` automaticamente para comandos de investigação
- exemplos de investigação: `wehive terraform state list`, `wehive terraform state show <resource>`, `wehive terraform output`
- exemplos de operação: `make stateless.mkt.n8n.bootstrap.apply`, `make shared.kubernetes.status`
- padrões make disponíveis: `<scope>.<component>.<action>`
- actions: apply, plan, status, destroy, taint, taint.all, outputs, health

## segurança

- nunca destrua o state storage (platform/backend) sem confirmação explícita
- sempre faça backup do state antes de mudanças maiores
- use `terraform plan` para revisar mudanças antes de aplicar
- teste mudanças em ambientes não-produtivos quando possível
- nunca faça commit de valores sensíveis (`.env`, secrets) no controle de versão
