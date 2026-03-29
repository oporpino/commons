## princípios

- sempre escreva testes para novas features e correções de bugs
- prefira unit tests ao invés de integration tests quando possível
- use TDD — escreva o teste antes de implementar a feature
- testes devem ser independentes e isolados
- use nomes descritivos que explicam o que está sendo testado
- organize testes na mesma estrutura do código que testam

## testes atômicos

- escreva testes atômicos — tudo deve estar dentro do próprio teste
- não deve ser necessário navegar pelo arquivo para entender o teste
- configure e instancie tudo dentro do teste (não use setup compartilhado para dados de teste)
- cada teste deve ser completamente autocontido e legível sozinho
- evite dependências entre testes ou estado compartilhado

## padrão triple-a

- siga o padrão Triple A (Arrange-Act-Assert) em todos os testes
- sempre use comentários explícitos: `# arrange`, `# act`, `# assert`
- arrange: configure dados de teste e dependências no início
- act: execute o método ou funcionalidade sendo testada
- assert: verifique o resultado esperado
- mantenha cada fase focada e clara

## mocks

- use mocks em unit tests para isolar a unidade sendo testada
- mock dependências externas (APIs, serviços, databases) em unit tests
- NÃO use mocks em integration tests — teste o fluxo real
- mantenha mocks simples e focados no comportamento necessário

## assertions

- um assert por teste quando possível para clareza (máximo 3)
- múltiplos asserts permitidos apenas quando há benefícios claros
- cada assert deve testar um comportamento ou resultado específico

## cobertura

- priorize testes significativos ao invés de porcentagem de cobertura
- sempre teste edge cases e condições de erro
- teste cenários de sucesso (happy path) e falha (unhappy path)

## organização

- agrupe testes relacionados
- mantenha testes simples e legíveis
- evite lógica complexa em testes
- setup/teardown apenas para inicialização de ambiente (não para dados de teste)

## manutenção

- ao alterar código, SEMPRE atualize os testes para seguir os padrões das rules
- REGRA CRÍTICA: se está alterando o código, NÃO mexa nos testes anteriores sem pedir permissão
- REGRA CRÍTICA: se está consertando teste, NÃO altere o código que já está certo
- REGRA CRÍTICA: se um teste falhar após mudança de código, reporte ao usuário — não ajuste o teste para fazer passar
- evite falsos positivos — teste que passa mas código quebra regra de negócio
- separação clara: mudança de código = criar/atualizar testes | mudança de teste = não tocar código funcional
- quando precisar modificar testes existentes, peça confirmação antes descrevendo o que será alterado e por quê
- quando encontrar testes desatualizados (não seguindo padrões), refatore-os separadamente e peça confirmação ao usuário
