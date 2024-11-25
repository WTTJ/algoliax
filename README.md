# Algoliax

[![CircleCI](https://circleci.com/gh/WTTJ/algoliax/tree/main.svg?style=svg)](https://circleci.com/gh/WTTJ/algoliax/tree/main)
[![Module Version](https://img.shields.io/hexpm/v/algoliax.svg)](https://hex.pm/packages/algoliax)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/algoliax/)
[![Total Download](https://img.shields.io/hexpm/dt/algoliax.svg)](https://hex.pm/packages/algoliax)
[![License](https://img.shields.io/hexpm/l/algoliax.svg)](https://github.com/WTTJ/algoliax/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/WTTJ/algoliax.svg)](https://github.com/WTTJ/algoliax/commits/master)

This package let you easily integrate Algolia to your Elixir application. It can be used with built in Elixir struct or with [Ecto](https://github.com/elixir-ecto/ecto) schemas.

## Installation

The package can be installed by adding `:algoliax` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:algoliax, "~> 0.9.0"}
  ]
end
```

If using with Ecto schemas, Algoliax requires `:ecto`.

## Configuration

Algoliax needs only `:api_key` and `:application_id` config. These configs can either be on config files or using environment variables `ALGOLIA_API_KEY` and `ALGOLIA_APPLICATION_ID`.

```elixir
config :algoliax,
  api_key: "<API_KEY>",
  application_id: "<APPLICATION_ID>",
  batch_size: 500,
  recv_timeout: 5000
```

## Usage

```elixir
defmodule People do
  use Algoliax.Indexer,
    index_name: :algoliax_people,
    object_id: :reference,
    algolia: [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(updated_at)"]
    ]

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil
end
```

Overridable functions:

- `to_be_indexed/1` which take the model struct in parameter: allows to choose to index or not the current model

```elixir
defmodule People do
  ...

  @impl Algoliax
  def to_be_indexed?(person) do
    person.age > 20
  end
end

# This object will be indexed
people1 = %People{reference: 10, last_name: "Doe", first_name: "John", age: 13}

# This object will not be indexed
people2 = %People{reference: 87, last_name: "Fred", first_name: "Al", age: 70}
```

- `build_object/1` which take the model struct/map in parameter and should return a Map: allow to add attributes to the indexed object. By default the object contains only an `ObjectID`.

```elixir
defmodule People do
  ...

  @impl Algoliax
  def build_object(person) do
    %{
      age: person.age,
      now: Date.utc_today()
    }
  end
end
```

- `build_object/2` does the same but provides the current index name as a second parameter. Can be useful when indexing the same model on multiple indexes (ie. for translations).

```elixir
defmodule Article do
  ...

  @impl Algoliax
  def build_object(author, "article_index_" <> locale) do
    %{
      author: article.author,
      content: article.content[locale]
    }
  end
end
```

#### Index name at runtime

It's possible to define an index name at runtime, useful if `index_name` depends on environment or comes from an environment variable.

To do this just define a function with an arity of 0 that will be used as `index_name`

```elixir
defmodule People do
  use Algoliax.Indexer,
    index_name: :algoliax_people,
    object_id: :reference,
    algolia: [...]

  def algoliax_people do
    System.get_env("PEOPLE_INDEX_NAME")
  end
end
```

#### Multiple indexes

It's possible to define multiple indexes for a same model.

To achieve this, just specify an array of index names, or simply return an array in your `index_name/0` runtime function

```elixir
defmodule Article do
  use Algoliax.Indexer,
    index_name: [:algoliax_article_fr, :algoliax_article_en],
    object_id: :reference,
    algolia: [...]
end
```

#### Index functions

```elixir
# Get people index settings
People.get_settings()

# Delete index
People.delete_index()

# Configure index
People.configure_index()
```

#### Object functions

```elixir
# Save object
People.save_object(people1)

# Save multiple objects
People.save_objects([people1, people2])

# Save multiple objects, and ensure object that they can't be indexed anymore are deleted from the index
People.save_objects([people1, people2], force_delete: true)

# Get object
People.get_object(people1)

# Delete object
People.delete_object(people1)
```

#### Search functions

```elixir
# search in index
People.search("john")

# search facet
People.search_facet("age")
```

#### Ecto specific

First you will need to add the Repo to the algoliax config:

```elixir
use Algoliax.Indexer,
  index_name: :algoliax_people,
  object_id: :reference
  repo: MyApp.Repo,
  algolia: [...]
```

If using Agoliax with an Ecto schema it is possible to use `reindex` functions. Reindex will go through all entries in the corresponding table (or part if query is provided). Algoliax will save_objects by batch of 500.
`batch_size` can be configured

```elixir
config :algoliax,
  batch_size: 250
```

> **NOTE:** Algoliax use by default the `id` column to order and go through the table. (cf [Custom order column](#custom-order-column))

```elixir
import Ecto.Query

# Reindex all
People.reindex()

# Reindex all people with age greater than 20
query = from(p in People, where: p.age > 20)
People.reindex(query)

# Reindex can also `force_delete`
query = from(p in People, where: p.age > 20)
People.reindex(query, force_delete: true)
People.reindex(force_delete: true)

# Reindex atomically (create a temporary index and move it to initial index)
People.reindex_atomic()
```

##### Custom cursor column

If you don't have an `id` column, you can change it by setting the `cursor_field` option either in the global settings or in schema specific settings.

Make sure this column ensure a consistent order even when new records are created.

- Using the global config:

```elixir
config :algoliax,
  batch_size: 250,
  cursor_field: :reference
```

- Indexer specific:

```elixir
defmodule People do
  use Algoliax.Indexer,
    index_name: :algoliax_people,
    object_id: :reference,
    repo: MyApp.Repo,
    cursor_field: :inserted_at,
    algolia: [...]
end
```

#### Replicas configuration

Replicas can be configured using `:replicas` options. This option accepts the following `:index_name`, `:algolia` and `:inherit`.
Use `inherit: true` on the replica if you want it to inherit from the primary settings, if custom settings in `:algolia` they will be merged.

```elixir
use Algoliax.Indexer,
  index_name: :algoliax_people,
  object_id: :reference,
  repo: MyApp.Repo,
  algolia: [
    attributes_for_faceting: ["age"],
    searchable_attributes: ["full_name"],
  ],
  replicas: [
    [index_name: :algoliax_by_age_asc, inherit: true, algolia: [ranking: ["asc(age)"]]],
    [index_name: :algoliax_by_age_desc, inherit: false, algolia: [ranking: ["desc(age)"]]]
  ]
```

If the main index holds multiple indexes (e.g for an index per language usecase), replicas need to hold the same amount of names.
The order is important to be associated to the correct main index.

```elixir
use Algoliax.Indexer,
  index_name: [:algoliax_article_en, :algoliax_article_fr],
  object_id: :reference,
  repo: MyApp.Repo,
  algolia: [
    attributes_for_faceting: ["published_at"],
    searchable_attributes: ["content"],
  ],
  replicas: [
    [index_name: [:algoliax_article_by_publication_asc_en, :algoliax_article_by_publication_asc_fr], inherit: true, algolia: [ranking: ["asc(published_at)"]]],
    [index_name: [:algoliax_article_by_publication_desc_en, :algoliax_article_by_publication_desc_fr], inherit: false, algolia: [ranking: ["desc(published_at)"]]]
  ]
```

## Copyright and License

Copyright (c) 2020 CORUSCANT (welcome to the jungle) - https://www.welcometothejungle.com

This library is licensed under the [BSD-2-Clause](./LICENSE.md).
