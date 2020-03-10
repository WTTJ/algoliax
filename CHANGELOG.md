## v0.3.0 (dev)

#### New

- add `prepare_object` to modify object before send to algolia

#### Bug fix

- Fix pagination when `cursor_field` different than `:id`

#### breaking changes

- Move algoliax to algoliax/indexer.
  change

```elixir
use Algoliax,
  ...
# to
use Algoliax.Indexer,
  ...
```

## v0.2.0 (2020-01-27)

### Enhancements

- add option to customize column used to find records in batch (`cursor_field`)
- add preloads to find records in batch.
