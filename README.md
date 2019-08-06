# Algoliax

This package let you easily integrate Algolia to your elixir application. It can be used with built in elixir struct or with [ecto](https://github.com/elixir-ecto/ecto) schemas.

## Installation

The package can be installed by adding `algoliax` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:algoliax, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/algoliax](https://hexdocs.pm/algoliax).

## Configuration

Algoliax needs only `:api_key` and `application_id` config. These configs can either be on config files or using environment varialble `"ALGOLIA_API_KEY"` and `"ALGOLIA_APPLICATION_ID"`.

```elixir
config :algoliax,
  api_key: "<API_KEY>",
  application_id: "<APPLICATION_ID>"
```

## Usage

```elixir
defmodulePeople do
  use Algoliax,
    index_name: :algoliax_people,
    attributes_for_faceting: ["age"],
    searchable_attributes: ["full_name"],
    custom_ranking: ["desc(update_at)"],
    object_id: :reference

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  attributes([:first_name, :last_name, :age])

  attribute(:updated_at, DateTime.utc_now() |> DateTime.to_unix())

  attribute :full_name do
    Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
  end

  attribute :nickname do
    Map.get(model, :first_name, "") |> String.downcase()
  end
end
```

#### Available functions

```elixir
people1 = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20}

people2 = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20}

# Get people index settings
People.get_settings()

# Delete index
People.delete_index()

# Save one object
People.save_object(people1)

# Save multiple objects
People.save_objects([people1, people2])

# Save multiple objects, and ensure object that they can't be indexed are deleted
People.save_objects([people1, people2], force_delete: true)

# Get on object
People.get_object(people1)

# Delete one object
People.delete_object(people1)
```

Ecto specific functions:

```elixir
import Ecto.Query

# Reindex all
People.reindex()

# Reindex all people with age greater than 20
query = from(p in People, where: p.age > 20)
People.reindex(query)

# Reindex Atomicly (create a temporary index)
People.reindex_atomic()
```
