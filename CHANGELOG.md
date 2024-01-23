# Changelog

## v0.8.1 - 2024-01-23

#### New

- Added new **optional** settings `default_filters` to be applied automatically when calling `reindex` without query
  or `reindex_atomic`. Defaults to `%{}` which was the previous behavior.

```elixir
defmodule BlondeBeerIndexer do
  use Algoliax.Indexer,
    index_name: :blonde_beers,
    object_id: :name,
    schemas: [Beer],
    default_filters: %{where: [kind: "blonde"]}
end

defmodule BeerIndexer do
  use Algoliax.Indexer,
    index_name: :various_beers,
    object_id: :name,
    schemas: [Beer1, Beer2],
    default_filters: :get_filters
    
  def get_filters do
    %{
      Beer1 => %{where: [kind: "blonde"]}, 
      Beer2 => %{where: [kind: "brune"]}
    }
  end
end
```

#### Contributing

- New `CONTRIBUTING.md` file
- Simplified the `config/test.exs` file
- Provide a `.env.example` file to help contributors to setup their environment

## v0.8.0 - 2023-09-20

#### Breaking changes

- Errors for `get_object` and `get_objects` are now of arity 4 and returns the original request as last attribute

#### New

- Added possibility to have multiple indexes for a model (applies for replicas as well)
- Added `build_object/2` with the index name as second parameter (useful for translations for example)

## v0.7.2 - 2023-09-18

#### Breaking changes

- require Elixir >= 1.15 and OTP 26

## v0.7.1 - 2022-03-29

#### New

- Add wait_task/1 (https://hexdocs.pm/algoliax/Algoliax.html#wait_task/1)

## v0.7.0 - 2022-03-29

#### Breaking changes

- Indexer operation returns a `%Algoliax.Reponse{}` (#51)

#### Bug fix

- Ensure clean up on reindex fail

## v0.6.0 - 2021-06-10

#### Updates

- Replace deprecated `hmac` function with new :crypto API `mac` function to support OTP-24

#### Breaking changes

- Drop support for OTP 21. OTP 22+ is now required.

## v0.5.0 - 2021-03-04

#### New

- [Welcome to the Jungle](https://www.welcometothejungle.com) became the owner :tada:
- Add ability to define replicas
- Raise when Algolia API error

#### Breaking changes

- `generate_secured_api_key/1` is removed in favor of `generate_secured_api_key/2`
- Drop support of Elixir 1.9. Elixir 1.10 or greater required

#### Updates

- update hackney to 1.17

## v0.4.3 - 2020-08-31

#### New

- add ability to customize objectID by overriding `get_object_id/1`

#### Improvement

- Make sure index is configured before any action.

## v0.4.2 - 2020-05-14

#### New

- add ability to provide preloads for `reindex` and `reindex_atomic` function

```elixir
defmodule People do
  use Algoliax.Indexer,
    index_name: :people,
    object_id: :reference,
    schemas: [
      {__MODULE__, [:animals]}
    ]
    algolia: [
      attribute_for_faceting: ["age"],
      custom_ranking: ["desc(updated_at)"]
    ]

end
```

## v0.4.1 - 2020-05-01

#### New

- add `generate_secured_api_key!/1`

## v0.4.0 - 2020-04-24

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

- improved `generate_secured_api_key/1`
- remove attributes macros in favor of `build_object/1`
- remove `:prepare_object` options
- remove `:preloads` options

## v0.3.0 - 2020-04-04

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

## v0.2.0 - 2020-01-27

### Enhancements

- add option to customize column used to find records in batch (`cursor_field`)
- add preloads to find records in batch.
