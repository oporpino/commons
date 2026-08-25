## seeds & fixtures

- toda feature deve ter dados representados em factories/fixtures (testes) e seeds (ambiente de dev)
- seeds são obrigatórios — o ambiente de desenvolvimento deve funcionar após `make run.seed`
- factories são obrigatórias — testes não devem criar dados ad-hoc fora de factories
- seeds devem ser idempotentes — rodar duas vezes não pode duplicar dados
- nunca use IDs hardcoded em seeds — use lookups ou deixe o banco gerar
- seeds devem cobrir os estados relevantes da entidade (ex: ativo/inativo, pendente/aprovado)
- mantenha os dados de seed realistas mas mínimos

## localização por stack

| Stack | Factories / Fixtures | Seeds |
|-------|----------------------|-------|
| Ruby (Rails) | `test/factories/<model>.rb` | `db/seeds/` ou `db/seeds.rb` |
| Elixir (Phoenix) | `test/support/factory.ex` | `priv/repo/seeds.exs` |
| Django | `<app>/tests/factories.py` | `<app>/fixtures/<model>.json` |
| React | `src/__tests__/fixtures/<feature>.ts` | N/A |

## padrões de idempotência

```ruby
# Ruby — Rails
Model.find_or_create_by!(field: value)
```

```elixir
# Elixir — Ecto
Repo.insert!(%Model{field: value}, on_conflict: :nothing, conflict_target: :field)
```

```python
# Django
Model.objects.get_or_create(field=value)
```

## checklist antes de considerar a feature pronta

- [ ] factory criada ou atualizada para o modelo
- [ ] seed criado ou atualizado com dados realistas
- [ ] seed é idempotente (verificado rodando duas vezes)
- [ ] `make run.seed` executa sem erro
- [ ] testes passam usando as factories
