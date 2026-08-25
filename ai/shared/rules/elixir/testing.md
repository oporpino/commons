# Testing Standards & Requirements

## 🎯 Coverage Requirements

### Minimum Coverage

- **Use Cases:** 100% coverage (non-negotiable)
- **Domain Entities (Structs):** 90% coverage
- **Repositories:** 80% coverage
- **Controllers:** 80% coverage
- **Utilities/Helpers:** 90% coverage
- **Overall Project:** 80% minimum

### Coverage Tools
```bash
# Run tests with coverage
mix test --cover

# Generate detailed HTML report
mix coveralls.html
```

Add to `mix.exs`:
```elixir
def project do
  [
    # ...
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test
    ]
  ]
end

defp deps do
  [
    {:excoveralls, "~> 0.18", only: :test}
  ]
end
```

---

## 📁 Test Structure

### File Organization
```
test/
├── support/              # Test helpers and utilities
│   ├── factory.ex       # Data factories
│   ├── mocks.ex         # Common mocks
│   └── fixtures.ex      # Test fixtures
├── your_app/
│   └── context/
│       ├── entity_test.exs
│       ├── repos/
│       │   └── entity_repo_test.exs
│       └── use_cases/
│           ├── create_entity_test.exs
│           ├── update_entity_test.exs
│           └── delete_entity_test.exs
└── your_app_web/
    └── controllers/
        └── entity_controller_test.exs
```

### Test File Template
```elixir
defmodule YourApp.Context.UseCases.CreateEntityTest do
  use ExUnit.Case, async: true
  
  alias YourApp.Context.Entity
  alias YourApp.Context.UseCases.CreateEntity

  # Mocks
  defmodule MockRepo do
    def insert(entity), do: {:ok, %{entity | id: "generated_id"}}
  end

  defmodule FailingRepo do
    def insert(_entity), do: {:error, :database_error}
  end

  describe "execute/2" do
    setup do
      valid_entity = %Entity{
        name: "Test",
        value: 100,
        status: :active
      }

      {:ok, entity: valid_entity}
    end

    test "creates entity successfully with valid data", %{entity: entity} do
      assert {:ok, result} = CreateEntity.execute(entity, MockRepo)
      assert result.id == "generated_id"
      assert result.name == "Test"
    end

    test "returns error when entity is invalid" do
      invalid_entity = %Entity{name: nil, value: 100, status: :active}
      
      assert {:error, :name_required} = CreateEntity.execute(invalid_entity, MockRepo)
    end

    test "returns error when repository fails", %{entity: entity} do
      assert {:error, :database_error} = CreateEntity.execute(entity, FailingRepo)
    end
  end

  describe "edge cases" do
    test "handles empty values correctly" do
      # edge case tests
    end

    test "handles maximum values correctly" do
      # edge case tests
    end
  end
end
```

---

## 📝 Naming Conventions

### Test Module Names
```elixir
# ✅ GOOD - Mirrors production module with Test suffix
defmodule Shop.UseCases.CreateOrderTest do
  # tests for Shop.UseCases.CreateOrder
end

# ❌ BAD - Unclear or inconsistent naming
defmodule CreateOrderTests do
end
```

### Test Names
```elixir
# ✅ GOOD - Describes behavior clearly
test "creates order successfully when all validations pass"
test "returns error when customer does not exist"
test "sends confirmation email after successful payment"
test "calculates discount correctly for premium customers"

# ❌ BAD - Vague or technical jargon only
test "test_create"
test "success case"
test "error"
test "case_1"
```

### Describe Blocks
```elixir
# ✅ GOOD - Groups related tests
describe "execute/2" do
  test "with valid params"
  test "with invalid params"
end

describe "validations" do
  test "validates email format"
  test "validates required fields"
end

describe "edge cases" do
  test "handles empty list"
  test "handles nil values"
end

# ❌ BAD - No organization
test "validates email format"
test "creates order"
test "handles nil"
```

---

## 🧪 Required Test Cases

### For Every Use Case

#### 1. Happy Path
```elixir
test "executes successfully with valid input" do
  assert {:ok, result} = UseCase.execute(valid_params)
  assert result.field == expected_value
end
```

#### 2. Validation Errors
```elixir
test "returns error when required field is missing" do
  assert {:error, :field_required} = UseCase.execute(invalid_params)
end

test "returns error when field format is invalid" do
  assert {:error, :invalid_format} = UseCase.execute(bad_format_params)
end
```

#### 3. Dependency Failures
```elixir
test "returns error when repository fails" do
  assert {:error, :database_error} = UseCase.execute(params, FailingRepo)
end

test "returns error when external service fails" do
  assert {:error, :service_unavailable} = UseCase.execute(params, FailingService)
end
```

#### 4. Edge Cases
```elixir
test "handles empty list correctly" do
  assert {:ok, result} = UseCase.execute(%{items: []})
  assert result.total == Decimal.new(0)
end

test "handles maximum values" do
  large_value = %{quantity: 999_999}
  assert {:ok, result} = UseCase.execute(large_value)
end

test "handles special characters in strings" do
  special_chars = %{name: "Test's \"Name\" & More"}
  assert {:ok, result} = UseCase.execute(special_chars)
end
```

#### 5. Business Rules
```elixir
test "applies discount only for premium customers" do
  premium_customer = %{tier: :premium}
  assert {:ok, result} = UseCase.execute(premium_customer)
  assert result.discount > 0
end

test "does not apply discount for regular customers" do
  regular_customer = %{tier: :regular}
  assert {:ok, result} = UseCase.execute(regular_customer)
  assert result.discount == 0
end
```

---

## 🎭 Mocking Strategies

### Simple Mock Modules
```elixir
defmodule MockRepo do
  def insert(entity), do: {:ok, %{entity | id: "mock_id"}}
  def get("valid_id"), do: {:ok, %Entity{id: "valid_id"}}
  def get(_), do: {:error, :not_found}
end
```

### Parameterized Mocks
```elixir
defmodule MockRepoBuilder do
  def build(responses) do
    defmodule DynamicMock do
      def insert(_), do: Map.get(responses, :insert, {:ok, %{}})
      def get(_), do: Map.get(responses, :get, {:ok, %{}})
    end
  end
end

# Usage
test "with custom mock" do
  mock = MockRepoBuilder.build(%{
    insert: {:error, :duplicate},
    get: {:ok, %Entity{}}
  })
  
  assert {:error, :duplicate} = UseCase.execute(params, mock)
end
```

### Using Mox (Recommended for Complex Cases)
```elixir
# In test/support/mocks.ex
Mox.defmock(YourApp.MockRepo, for: YourApp.RepoBehaviour)

# In test
import Mox

setup :verify_on_exit!

test "creates order with mocked repo" do
  expect(YourApp.MockRepo, :insert, fn order ->
    {:ok, %{order | id: "123"}}
  end)
  
  assert {:ok, result} = CreateOrder.execute(order, YourApp.MockRepo)
end
```

### Mock Guidelines

✅ **DO:**
- Create simple, focused mocks
- Mock at boundaries (repos, services)
- Return realistic data structures
- Keep mocks close to tests that use them

❌ **DON'T:**
- Mock internal functions
- Over-complicate mocks
- Share stateful mocks between tests
- Mock the system under test

---

## 🏗️ Test Organization

### Setup and Helpers
```elixir
defmodule Shop.UseCases.CreateOrderTest do
  use ExUnit.Case, async: true

  # Common setup for all tests
  setup do
    customer = %Customer{id: 1, name: "John"}
    product = %Product{id: 1, price: Decimal.new("10.00")}
    
    {:ok, customer: customer, product: product}
  end

  # Specific setup for describe block
  describe "with valid items" do
    setup %{product: product} do
      items = [%{product: product, quantity: 2}]
      {:ok, items: items}
    end

    test "calculates total correctly", %{items: items} do
      # test implementation
    end
  end

  # Helper functions
  defp build_order(attrs \\ %{}) do
    default_attrs = %{
      customer_id: 1,
      items: [],
      status: :pending
    }
    
    struct(Order, Map.merge(default_attrs, attrs))
  end
end
```

### Fixtures and Factories
```elixir
# test/support/factory.ex
defmodule YourApp.Factory do
  alias YourApp.{Order, Customer, Product}

  def build(:customer, attrs \\ %{}) do
    default = %Customer{
      id: sequence(:customer_id),
      name: "Customer #{sequence(:customer_name)}",
      email: "customer#{sequence(:email)}@example.com"
    }
    
    struct(default, attrs)
  end

  def build(:order, attrs \\ %{}) do
    default = %Order{
      id: sequence(:order_id),
      customer_id: 1,
      items: [],
      total: Decimal.new(0),
      status: :pending
    }
    
    struct(default, attrs)
  end

  defp sequence(key) do
    Agent.get_and_update(__MODULE__, fn state ->
      current = Map.get(state, key, 0)
      {current + 1, Map.put(state, key, current + 1)}
    end)
  end
end

# Usage in tests
test "creates order" do
  customer = Factory.build(:customer)
  order = Factory.build(:order, customer_id: customer.id)
  
  assert {:ok, _} = CreateOrder.execute(order)
end
```

---

## ⚡ Test Performance

### Async Tests
```elixir
# ✅ GOOD - Run tests in parallel when possible
defmodule MyTest do
  use ExUnit.Case, async: true
  
  # Tests run in parallel
end

# ⚠️ CAUTION - Use async: false for tests that:
# - Modify global state
# - Use shared resources (files, ports)
# - Depend on execution order
defmodule IntegrationTest do
  use ExUnit.Case, async: false
  
  # Tests run sequentially
end
```

### Test Speed Guidelines

- Unit tests should run in **< 10ms each**
- Integration tests should run in **< 100ms each**
- Full test suite should run in **< 30 seconds**

### Optimizing Slow Tests
```elixir
# ❌ BAD - Slow setup
setup do
  # Heavy database seeding
  # Multiple API calls
  # Complex data generation
end

# ✅ GOOD - Minimal setup
setup do
  # Only create what's needed
  # Use factories for quick data generation
  # Mock external services
end
```

---

## 📊 Test Patterns

### Testing Structs
```elixir
defmodule Shop.OrderTest do
  use ExUnit.Case
  
  alias Shop.Order

  describe "new/1" do
    test "creates order with valid attributes" do
      attrs = %{customer_id: 1, items: []}
      assert %Order{} = Order.new(attrs)
    end
  end

  describe "validate/1" do
    test "returns :ok for valid order" do
      order = %Order{customer_id: 1, items: [%{id: 1}], status: :pending}
      assert :ok = Order.validate(order)
    end

    test "returns error when customer_id is nil" do
      order = %Order{customer_id: nil, items: [], status: :pending}
      assert {:error, :customer_required} = Order.validate(order)
    end
  end

  describe "calculate_total/1" do
    test "calculates total from items" do
      items = [
        %{price: Decimal.new("10.00"), quantity: 2},
        %{price: Decimal.new("5.00"), quantity: 1}
      ]
      order = %Order{customer_id: 1, items: items, status: :pending}
      
      result = Order.calculate_total(order)
      
      assert result.total == Decimal.new("25.00")
    end

    test "returns zero for empty items" do
      order = %Order{customer_id: 1, items: [], status: :pending}
      
      result = Order.calculate_total(order)
      
      assert result.total == Decimal.new("0")
    end
  end
end
```

### Testing with Pattern Matching
```elixir
test "returns expected structure" do
  assert {:ok, %Order{id: id, total: total}} = CreateOrder.execute(params)
  assert is_binary(id)
  assert Decimal.positive?(total)
end
```

### Testing Error Messages
```elixir
test "returns descriptive error messages" do
  assert {:error, :customer_required} = UseCase.execute(%{customer_id: nil})
  assert {:error, :items_empty} = UseCase.execute(%{items: []})
  assert {:error, :invalid_status} = UseCase.execute(%{status: :unknown})
end
```

---

## 🚫 Common Testing Anti-Patterns

### ❌ Testing Implementation Details
```elixir
# BAD - Tests internal private functions
test "private_helper_function works" do
  # Don't test private functions directly
end

# GOOD - Test through public interface
test "public_function produces correct result" do
  # Private functions are tested indirectly
end
```

### ❌ Brittle Tests
```elixir
# BAD - Tests exact output format
test "formats output" do
  assert format(data) == "Exactly this string with no flexibility"
end

# GOOD - Tests essential behavior
test "includes required information in output" do
  result = format(data)
  assert result =~ "essential_info"
  assert String.contains?(result, "required_data")
end
```

### ❌ Test Interdependence
```elixir
# BAD - Tests depend on each other
test "step 1" do
  # Creates global state
end

test "step 2" do
  # Depends on step 1 running first
end

# GOOD - Independent tests
test "step 1" do
  # Setup and teardown within test
end

test "step 2" do
  # Complete setup within test
end
```

### ❌ Over-Mocking
```elixir
# BAD - Mocking everything
test "creates order" do
  mock1 = Mock.new()
  mock2 = Mock.new()
  mock3 = Mock.new()
  # Too many mocks, testing nothing real
end

# GOOD - Mock at boundaries only
test "creates order" do
  mock_repo = MockRepo  # Only mock external dependencies
  # Test real business logic
end
```

---

## ✅ Test Checklist

Before considering a feature complete:

- [ ] All happy paths tested
- [ ] All validation errors tested
- [ ] All dependency failures tested
- [ ] Edge cases covered
- [ ] Business rules verified
- [ ] Error messages are descriptive
- [ ] Tests run in < 10ms (unit tests)
- [ ] Tests are independent
- [ ] Tests use meaningful names
- [ ] Coverage meets requirements (100% for use cases)
- [ ] No skipped tests without good reason
- [ ] Mocks are simple and focused

---

## 📖 Complete Test Example
```elixir
defmodule Shop.UseCases.CreateOrderTest do
  use ExUnit.Case, async: true
  
  alias Shop.Order
  alias Shop.UseCases.CreateOrder

  # === MOCKS ===
  
  defmodule MockRepo do
    def insert(order) do
      {:ok, %{order | id: Ecto.UUID.generate()}}
    end
  end

  defmodule FailingRepo do
    def insert(_order), do: {:error, :database_error}
  end

  # === SETUP ===
  
  describe "execute/2" do
    setup do
      valid_order = %Order{
        customer_id: 1,
        items: [
          %{product_id: 1, price: Decimal.new("10.00"), quantity: 2}
        ],
        status: :pending
      }

      {:ok, order: valid_order}
    end

    # === HAPPY PATH ===
    
    test "creates order successfully with valid data", %{order: order} do
      assert {:ok, result} = CreateOrder.execute(order, MockRepo)
      
      assert result.id != nil
      assert result.customer_id == 1
      assert result.status == :pending
      assert result.total == Decimal.new("20.00")
    end

    # === VALIDATION ERRORS ===
    
    test "returns error when customer_id is nil" do
      invalid_order = %Order{customer_id: nil, items: [], status: :pending}
      
      assert {:error, :customer_required} = CreateOrder.execute(invalid_order, MockRepo)
    end

    test "returns error when items list is empty", %{order: order} do
      empty_order = %{order | items: []}
      
      assert {:error, :items_required} = CreateOrder.execute(empty_order, MockRepo)
    end

    test "returns error when items exceed maximum" do
      items = Enum.map(1..101, fn i ->
        %{product_id: i, price: Decimal.new("1.00"), quantity: 1}
      end)
      order = %Order{customer_id: 1, items: items, status: :pending}
      
      assert {:error, :too_many_items} = CreateOrder.execute(order, MockRepo)
    end

    # === DEPENDENCY FAILURES ===
    
    test "returns error when repository fails", %{order: order} do
      assert {:error, :database_error} = CreateOrder.execute(order, FailingRepo)
    end

    # === EDGE CASES ===
    
    test "handles decimal precision correctly" do
      items = [
        %{product_id: 1, price: Decimal.new("10.99"), quantity: 3}
      ]
      order = %Order{customer_id: 1, items: items, status: :pending}
      
      assert {:ok, result} = CreateOrder.execute(order, MockRepo)
      assert result.total == Decimal.new("32.97")
    end

    test "handles large quantities" do
      items = [
        %{product_id: 1, price: Decimal.new("1.00"), quantity: 1000}
      ]
      order = %Order{customer_id: 1, items: items, status: :pending}
      
      assert {:ok, result} = CreateOrder.execute(order, MockRepo)
      assert result.total == Decimal.new("1000.00")
    end

    # === BUSINESS RULES ===
    
    test "calculates total before saving", %{order: order} do
      order_without_total = %{order | total: nil}
      
      assert {:ok, result} = CreateOrder.execute(order_without_total, MockRepo)
      assert result.total != nil
      assert result.total == Decimal.new("20.00")
    end
  end
end
```

---

## 🎯 Summary

1. **Coverage**: 100% for use cases, 80% minimum overall
2. **Organization**: Clear structure with describe blocks and setup
3. **Naming**: Descriptive test names that explain behavior
4. **Test Cases**: Happy path + validations + errors + edge cases
5. **Mocking**: Simple mocks at boundaries only
6. **Performance**: Fast, async tests when possible
7. **Independence**: Tests should not depend on each other

---

**Last Updated:** December 2025  
**Version:** 1.0
