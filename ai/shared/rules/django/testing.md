## framework

- use o framework de testes nativo do Django (baseado em unittest)
- use pytest-django para features de teste mais avançadas
- testes ficam em `tests/` ou `tests.py` dentro de cada app
- convenção de nomes: `test_*.py` para arquivos de teste
- organize testes por tipo: `test_models.py`, `test_views.py`, `test_api.py`

## comandos

- use `python manage.py test` para rodar testes
- use `pytest` para projetos com pytest-django
- use `--parallel` para execução paralela
- use `--keepdb` para preservar o banco de testes entre execuções
- configure test settings em `settings/test.py`

## boas práticas

- use `TestCase` do Django para testes que precisam de acesso ao banco
- use `SimpleTestCase` para testes sem banco (mais rápido)
- use `TransactionTestCase` apenas para testar comportamento de transações
- use o test client do Django para testar views
- use `APIClient` do DRF para testar endpoints de API
- use factories (factory_boy) ou fixtures para dados de teste
- teste métodos, properties e managers de models
- teste permissões e autenticação de views
- teste validação e limpeza de formulários
- mock serviços externos e chamadas de API
- teste signal handlers quando usar signals

## padrões

- use `setUp` e `tearDown` para setup/cleanup de testes
- use `setUpTestData` para dados no nível de classe (mais rápido)
- teste cenários de sucesso e de erro
- teste otimização de querysets (select_related, prefetch_related)
- use `assertNumQueries` para testar quantidade de queries
- teste middleware e decorators customizados
- use `override_settings` para testar com configurações diferentes

## cobertura

- use `coverage.py` para relatórios de cobertura
- rode com: `coverage run --source='.' manage.py test`
- gere relatório com: `coverage report` ou `coverage html`
- priorize testes significativos ao invés de porcentagem de cobertura
