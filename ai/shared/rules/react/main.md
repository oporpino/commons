## geral

- use functional components com hooks ao invés de class components
- prefira TypeScript ao invés de JavaScript para type safety
- use patterns modernos do React (hooks, context, suspense)
- siga as boas práticas e convenções do React
- use ESLint e Prettier para formatação de código

## estrutura

- organize componentes em `src/components/`
- use estrutura baseada em features quando apropriado
- mantenha componentes pequenos e focados em responsabilidade única
- separe container components de presentational components
- use custom hooks para extrair lógica reutilizável

## boas práticas

- use nomes significativos para componentes e props
- evite prop drilling — use Context API ou gerenciamento de estado quando necessário
- memoize computações custosas com `useMemo`
- memoize callback functions com `useCallback`
- use `React.memo` para memoização de componentes quando apropriado
- trate estados de loading e erro corretamente
- evite funções inline em JSX quando possível por questões de performance
