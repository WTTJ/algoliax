## v0.4.0 (dev)

#### New

- add ability configure `:recv_timeout` for hackney.
- add ability to pass query_filters or Ecto.Query to `reindex/2`.

```elixir
filters = %{where: [name: "John"]}
People.reindex(filters)

query = from(p in People, where: p.name == "john")
People.reindex(query)
```

#### breaking changes

- remove attributes macros in favor of `build_object/1`
- remove `:prepare_object` options
- remove `:preloads` options

## v0.3.0

#### New

- add `prepare_object` to modify object before send to algolia
- add ability to provide `build_object/1` instead of attributes
- add `schemas` option to override caller

#### Bug fix

- Fix pagination when `cursor_field` different than `:id`
- `delete_object/1` and `reindex` w/ `force_delete: true` don't need to build entire object

#### breaking changes

- change dependencies to optional (ecto)
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
