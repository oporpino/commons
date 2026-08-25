## framework

- use Jest como test runner
- use React Testing Library para testes de componentes
- evite Enzyme, prefira React Testing Library
- testes ficam em pastas `__tests__` ou arquivos `*.test.ts(x)`
- convenção de nomes: `ComponentName.test.tsx`

## comandos

- use `npm test` ou `yarn test` para rodar testes
- use `--watch` para modo watch
- use `--coverage` para relatórios de cobertura
- configure Jest em `jest.config.js` ou `package.json`

## boas práticas

- teste comportamento do usuário, não detalhes de implementação
- use screen queries (`getByRole`, `getByText`) ao invés de container queries
- prefira accessible queries (`getByRole`) quando possível
- use `userEvent` ao invés de `fireEvent` para interações do usuário
- teste error boundaries e estados de loading
- mock dependências externas e chamadas de API
- use `waitFor` para assertions assíncronas
- evite testar estado interno — teste output e comportamento

## padrões

- use `data-testid` apenas como último recurso
- renderize componentes com os providers necessários (Router, Theme, etc)
- use custom render function com providers comuns
- teste acessibilidade com screen reader queries
- snapshot tests devem ser mínimos e significativos
