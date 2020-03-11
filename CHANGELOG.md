## v0.3.0 (dev)

#### New

- add `prepare_object` to modify object before send to algolia

#### Bug fix

- Fix pagination when `cursor_field` different than `:id`

#### breaking changes

- Move algoliax to algoliax/indexer.

```elixir
# old
use Algoliax,
  ...

# New
use Algoliax.Indexer,
  ...
```

- Move algolia specific settings into `:algolia` option

```elixir
# old
use Algoliax.Indexer,
  index_name: :test,
  attributes_for_faceting: ["age"],
  searchable_attributes: ["full_name"],
  custom_ranking: ["desc(updated_at)"],
  ...

# New
use Algoliax.Indexer,
  index_name: :test,
  algolia: [
    attributes_for_faceting: ["age"],
    searchable_attributes: ["full_name"],
    custom_ranking: ["desc(updated_at)"]
  ],
  ...

```

## v0.2.0 (2020-01-27)

### Enhancements

- add option to customize column used to find records in batch (`cursor_field`)
- add preloads to find records in batch.
