# Development Standards & Best Practices

> **Note**: For architecture and project structure, see [architecture.md](./architecture.md)
> For git workflow and commit standards, see [git.md](./git.md)
> For testing requirements, see [test.md](./test.md)

---

## 🧹 Code Quality Standards

### Function Size

**Maximum 20 lines per function** (public functions)
**Maximum 10 lines per helper** (private functions)

```elixir
# ✅ GOOD - Small and focused
def get_route(path, deps \\ default_deps()) do
  with {:error, :not_found} <- deps.cache.get(path),
       {:ok, config} <- deps.store.get(path) do
    deps.cache.put(path, config)
    {:ok, config}
  else
    {:ok, config} -> {:ok, config}
    error -> error
  end
end

# ❌ BAD - Too long, doing too much
def process_request(conn) do
  # 50 lines of parsing, validation, proxying, error handling...
  # Extract into smaller functions!
end
```

**Rule**: If you need to scroll to see the whole function, it's too big!

### File Size

**Maximum lines per file**:
- Structs: 100 lines
- Stores: 150 lines
- Use Cases: 100 lines
- Services: 200 lines
- Router: 300 lines

If a file exceeds these limits, split it into multiple files.

### Parameter Count

**Maximum 3 parameters per function** (excluding dependency injection map)

```elixir
# ❌ BAD - Too many parameters
def proxy_request(method, url, headers, body, timeout, retries) do
  # ...
end

# ✅ GOOD - Single struct + dependencies
def proxy_request(%ProxyRequest{} = request, deps \\ default_deps()) do
  # ...
end

# ✅ GOOD - Map for options
def proxy_request(url, headers, opts \\ []) do
  timeout = Keyword.get(opts, :timeout, 5000)
  # ...
end
```

---

## 📝 Naming Conventions

### Descriptive Names

```elixir
# ✅ GOOD - Clear and descriptive
def get_route_with_cache_fallback(path)
def validate_upstream_url(url)
def extract_headers_from_conn(conn)

# ❌ BAD - Vague or abbreviated
def get(path)
def validate(url)
def extract(conn)
```

### Module Names

```elixir
# ✅ GOOD
Gateway.UseCases.GetRoute
Gateway.Stores.RouteStore
Gateway.Services.HttpClient
Gateway.Structs.Route

# ❌ BAD
Gateway.GetRoute  # Where does it belong?
Gateway.Utils     # Too vague
Gateway.Helper    # What kind of helper?
```

### Variable Names

```elixir
# ✅ GOOD
route_config = get_config(path)
upstream_url = config.upstream
timeout_ms = config.timeout

# ❌ BAD
rc = get_config(path)
url = config.upstream  # url or upstream_url?
t = config.timeout
```

---

## 🎯 Code Style

### Pattern Matching > Conditionals

```elixir
# ✅ GOOD - Clear pattern matching
def handle_response({:ok, data}), do: process_data(data)
def handle_response({:error, :timeout}), do: {:error, :upstream_timeout}
def handle_response({:error, reason}), do: {:error, reason}

# ❌ BAD - Nested if/else
def handle_response(response) do
  if response.status == :ok do
    process_data(response.data)
  else
    if response.reason == :timeout do
      {:error, :upstream_timeout}
    else
      {:error, response.reason}
    end
  end
end
```

### Pipeline > Nesting

```elixir
# ✅ GOOD - Readable pipeline
def format_route_path(path) do
  path
  |> String.trim()
  |> String.downcase()
  |> ensure_leading_slash()
end

# ❌ BAD - Confusing nesting
def format_route_path(path) do
  ensure_leading_slash(String.downcase(String.trim(path)))
end
```

### With > Nested Case

```elixir
# ✅ GOOD - Clean with statement
def create_route(params) do
  with {:ok, route} <- validate_params(params),
       {:ok, _} <- check_uniqueness(route.path),
       {:ok, saved} <- save_route(route) do
    {:ok, saved}
  end
end

# ❌ BAD - Nested case statements
def create_route(params) do
  case validate_params(params) do
    {:ok, route} ->
      case check_uniqueness(route.path) do
        {:ok, _} ->
          case save_route(route) do
            {:ok, saved} -> {:ok, saved}
            error -> error
          end
        error -> error
      end
    error -> error
  end
end
```

---

## 📦 Dependency Injection

All use cases must support dependency injection for testing.

### Standard Pattern

```elixir
defmodule Gateway.UseCases.GetRoute do
  @type deps :: %{
    cache: module(),
    store: module()
  }

  def execute(path, deps \\ default_deps()) do
    # Use deps.cache and deps.store
  end

  defp default_deps do
    %{
      cache: Gateway.Stores.RouteCache,
      store: Gateway.Stores.RouteStore
    }
  end
end
```

### In Tests

```elixir
defmodule MockCache do
  def get(_), do: {:error, :not_found}
end

defmodule MockStore do
  def get("/test"), do: {:ok, %{upstream: "http://test"}}
end

test "retrieves route from store on cache miss" do
  deps = %{cache: MockCache, store: MockStore}
  assert {:ok, config} = GetRoute.execute("/test", deps)
end
```

---

## 🔍 Error Handling

### Consistent Error Returns

Always return `{:ok, result}` or `{:error, reason}`.

```elixir
# ✅ GOOD - Consistent tuples
def get_route(path) do
  case RouteStore.get(path) do
    {:ok, config} -> {:ok, config}
    {:error, :not_found} -> {:error, :route_not_found}
    {:error, reason} -> {:error, reason}
  end
end

# ❌ BAD - Inconsistent returns
def get_route(path) do
  case RouteStore.get(path) do
    {:ok, config} -> config  # Not a tuple!
    {:error, reason} -> nil  # Lost the error!
  end
end
```

### Descriptive Error Atoms

```elixir
# ✅ GOOD - Clear error reasons
{:error, :route_not_found}
{:error, :upstream_timeout}
{:error, :invalid_upstream_url}
{:error, :duplicate_route}

# ❌ BAD - Generic or unclear
{:error, :error}
{:error, :bad}
{:error, :failed}
```

---

## 📚 Documentation

### Module Documentation

Every module must have `@moduledoc`.

```elixir
defmodule Gateway.UseCases.ProxyRequest do
  @moduledoc """
  Proxies an HTTP request to the configured upstream service.

  This use case orchestrates the entire proxy flow:
  1. Retrieve route configuration
  2. Build upstream request
  3. Execute HTTP request
  4. Return formatted response

  ## Examples

      iex> ProxyRequest.execute(conn)
      {:ok, %{status: 200, headers: [...], body: "..."}}

      iex> ProxyRequest.execute(conn)
      {:error, :route_not_found}
  """
end
```

### Function Documentation

Public functions should have `@doc` and `@spec`.

```elixir
@doc """
Retrieves a route configuration with cache fallback.

Returns the route from cache if available, otherwise fetches from
Redis and warms the cache.

## Parameters

  * `path` - The route path to look up
  * `deps` - Dependencies map (for testing)

## Returns

  * `{:ok, config}` - Route configuration found
  * `{:error, :route_not_found}` - No route for this path
"""
@spec execute(String.t(), deps()) ::
  {:ok, map()} | {:error, :route_not_found | term()}
def execute(path, deps \\ default_deps()) do
  # ...
end
```

---

## 🚫 What to Avoid

### Don't Use Magic Numbers

```elixir
# ❌ BAD
defp default_timeout, do: 5000

# ✅ GOOD
@default_timeout_ms 5000
defp default_timeout, do: @default_timeout_ms
```

### Don't Leave Debug Code

```elixir
# ❌ BAD - Remove before committing
def process(data) do
  IO.inspect(data, label: "DEBUG")
  dbg(data)
  # ...
end

# ✅ GOOD - Use proper logging if needed
def process(data) do
  Logger.debug("Processing data: #{inspect(data)}")
  # ...
end
```

### Don't Comment Out Code

```elixir
# ❌ BAD - Delete it, we have git
def process(data) do
  # old_process(data)
  # this_was_the_old_way(data)
  new_process(data)
end

# ✅ GOOD - Clean code
def process(data) do
  new_process(data)
end
```

### Don't Use Generic Names

```elixir
# ❌ BAD
def process(data)
def handle(input)
def do_stuff(thing)

# ✅ GOOD
def proxy_request(conn)
def validate_route(route)
def format_response(upstream_response)
```

---

## ✅ Pre-Commit Checklist

**ALWAYS run before committing:**

```bash
make run.lint    # Check format and lint
make run.test    # Run all tests
```

If lint fails, fix automatically with:

```bash
make run.lint.fix    # Fix format and lint issues
```

## ✅ Code Review Checklist

Before submitting code:

- [ ] **Ran `make run.lint` and `make run.test` successfully**
- [ ] All functions under 20 lines (public) / 10 lines (private)
- [ ] All files under size limits
- [ ] Max 3 parameters per function
- [ ] Descriptive names for modules, functions, variables
- [ ] Pattern matching used instead of if/else
- [ ] Pipelines used instead of nesting
- [ ] Dependencies injectable for testing
- [ ] Consistent error tuples `{:ok, _}` / `{:error, _}`
- [ ] All public modules have `@moduledoc`
- [ ] All public functions have `@doc` and `@spec`
- [ ] No debug code (`IO.inspect`, `dbg()`)
- [ ] No commented-out code
- [ ] No magic numbers
- [ ] Follows architecture in [architecture.md](./architecture.md)

---

## 🎯 Summary

1. **Size**: Functions <20 lines, files within limits
2. **Naming**: Descriptive, clear, consistent
3. **Style**: Pattern matching, pipelines, with statements
4. **Dependencies**: Injectable for testing
5. **Errors**: Consistent `{:ok, _}` / `{:error, _}` tuples
6. **Documentation**: `@moduledoc`, `@doc`, `@spec`
7. **Cleanliness**: No debug code, no comments, no magic

**Remember**: Simple and clear code is better than clever code.

---

**Last Updated:** December 2025
**Version:** 2.0
