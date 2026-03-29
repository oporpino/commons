## commit

- mensagens devem ter 60 chars, em apenas uma linha e não mencionar ia
- faça commits pequenos e atômicos, evite commits grandes e com muitas alterações
- faça commits por contextos: um commit por feature, por bug, por regra de negócio
- formato: `<type>: <subject>` — tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`, `ci`

## rebase

- sempre use rebase ao invés de merge
- nunca faça `git pull` sem `--rebase`
- use `--force-with-lease` ao invés de `--force` em feature branches
- nunca faça force push direto na main

## squash

- squash WIP commits antes de integrar na main
- cada commit final deve representar uma mudança lógica completa que passa todos os testes

## branches

- nunca faça commit diretamente na main
- crie feature branches: `feature/`, `fix/`, `refactor/`

## submodules

- ao ter novos commits em um submodule, primeiro faça push na branch main do submodule
- depois, atualize o ponteiro no projeto raiz com commit separado referenciando o submodule atualizado
- nunca atualize o ponteiro do submodule no projeto raiz sem antes ter feito push no submodule

## pull_request

- use pull_request para enviar mudanças para o main
- faça pull requests pequenos e atômicos, evite pull requests grandes e com muitas alterações
- faça pull requests por contextos: um pull request por feature, por bug, por regra de negócio
- os pull requests devem ter na mensagem: o tldr, o contexto da mudança, a lista de arquivos das mudanças e como testa
- na seção de mudanças, sempre cite os arquivos modificados/criados
- faça pull requests com mensagens claras, concisas e curtas — evite texto desnecessário
