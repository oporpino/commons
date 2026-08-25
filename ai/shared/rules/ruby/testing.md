## framework

- use RSpec ou Minitest baseado no padrão do projeto
- crie `run/test` autocontido que chama o framework diretamente (ex: `bundle exec rails test` ou `bundle exec rspec`)
- testes RSpec vão em `spec/`, testes Minitest vão em `test/`
- convenção de nomes: `*_spec.rb` para RSpec, `*_test.rb` para Minitest

## comandos

- use os targets make: `make run.test` (sequencial), `make run.test.parallel` (paralelo), `make run.test.watch` (watch), `make run.test.diff` (diff)
- sempre use `bundle exec` antes de comandos de teste
- use testes paralelos para suites grandes para melhorar performance
- configure `database.yml` com sufixo `TEST_ENV_NUMBER` para suporte a testes paralelos

## tipos de testes

- unit tests em `test/models/`, `test/services/`, `test/lib/` — USE MOCKS
- integration tests em `test/controllers/`, `test/requests/` — NÃO USE MOCKS
- unit tests testam unidade isolada com mocks de dependências
- integration tests testam fluxo completo sem mocks (teste real)
- use fixtures para dados em integration tests
- evite fixtures em unit tests (instancie dentro do teste)

## testes atômicos (minitest)

- escreva testes atômicos onde tudo é instanciado dentro do teste
- evite navegar pelo arquivo para entender o teste — mantenha tudo explícito no corpo do teste
- sempre use comentários `# arrange`, `# act`, `# assert` para identificar fases do teste
- em geral, cada teste deve ter apenas um assert (máximo 3)
- múltiplos asserts permitidos apenas quando há benefícios claros

## nomenclatura (minitest)

- inicie a descrição do teste com o nome do método sendo testado
- use apenas o nome do método para caso de sucesso (ex: `test "add"`)
- use nome do método mais variação de contexto para casos alternativos (ex: `test "add returns zero when adding a number and its opposite"`)
- seja descritivo sobre qual comportamento está sendo testado em casos alternativos

## padrão minitest

- use Minitest puro com métodos `def test_<description>`
- classe de teste herda de `Minitest::Test`
- cada teste é um método começando com `test_` seguido de descrição em snake_case
- use Triple A (Arrange-Act-Assert) com comentários explícitos
- mantenha tudo necessário para o teste dentro do método de teste (testes atômicos)

### exemplo completo

```ruby
# file: test/calculator_test.rb
require "minitest/autorun"
require_relative "../calculator"

class CalculatorTest < Minitest::Test
  def test_add
    # arrange
    calculator = Calculator.new
    a, b = 2, 3

    # act
    result = calculator.add(a, b)

    # assert
    assert_equal 5, result
  end

  def test_add_returns_zero_when_adding_a_number_and_its_opposite
    # arrange
    calculator = Calculator.new
    a, b = -3, 3

    # act
    result = calculator.add(a, b)

    # assert
    assert_equal 0, result
  end

  def test_divide_raises_when_dividing_by_zero
    # arrange
    calculator = Calculator.new
    a, b = 10, 0

    # act / assert
    assert_raises(ArgumentError) { calculator.divide(a, b) }
  end
end
```

## estrutura rspec

- organize testes espelhando a estrutura do código (`spec/models` para `app/models`, etc)
- use `let` e `let!` para setup de dados de teste no RSpec
- prefira `let!` ao invés de blocos `before` para clareza
- use contexts para agrupar cenários de teste relacionados
- use shared examples para padrões de teste comuns

## boas práticas

- use nomes descritivos que explicam o comportamento sendo testado
- teste edge cases e condições de erro
- mock serviços externos e APIs em unit tests para manter testes rápidos e isolados
- use factories (FactoryBot) para unit tests, fixtures para integration tests
- evite testar detalhes de implementação, foque no comportamento
- mantenha testes DRY mas legíveis (balance duplicação vs abstração)

## testes paralelos

- prepare databases paralelos com `make run.test.parallel.prepare`
- garanta que `database.yml` inclui `database: app_test<%= ENV['TEST_ENV_NUMBER'] %>`
- use gem `parallel_tests >= 5.5`
- espere speedup de 2-4x em sistemas multi-core

## ferramentas

- use gem `retest` para modos watch e diff
- use `simplecov` para relatórios de cobertura de testes
- use VCR para gravar interações HTTP em testes
- use `database_cleaner` para gerenciar estado do banco de testes
