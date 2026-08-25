## geral

- sempre use features do Ruby 3.x quando apropriado
- prefira métodos funcionais (`map`, `select`, `reduce`) ao invés de loops
- use symbols ao invés de strings para chaves de hash
- sempre use `bundle exec` antes de comandos
- siga as convenções do Ruby style guide

## estrutura

- organize o código em `app/`, `lib/`, `config/`, `spec/` ou `test/`
- use concerns para comportamentos compartilhados
- use service objects para lógica de negócio complexa
- mantenha controllers finos, models robustos (mas não exagerados)
- use POROs (Plain Old Ruby Objects) quando apropriado

## boas práticas

- prefira keyword arguments ao invés de positional arguments para métodos com múltiplos parâmetros
- use safe navigation operator (`&.`) para evitar nil checks
- prefira lazy evaluation ao trabalhar com coleções grandes
- use nomes significativos para variáveis e métodos
- evite métodos longos — divida em partes menores
