# Global index example

Sometimes we need to aggregate multiple resource from multiple schema into a single algolia index.

In this example we want to make a global index with all our dogs and cats. First we need both ecto schemas:

```elixir
defmodule MyApp.Cat do
  use Ecto.Schema

  schema "cats" do
    field(:kind)
    field(:name)
    field(:weight, :integer)

    timestamps()
  end
end

defmodule MyApp.Dog do
  use Ecto.Schema

  schema "dogs" do
    field(:kind)
    field(:name)
    field(:weight, :integer)

    timestamps()
  end
end
```

Let's build our global index using `:schemas` options

```elixir
defmodule MyApp.GlobalIndex do
  use Algoliax.Indexer,
    index_name: :global_index_name,
    repo: MyApp.Repo,
    schemas: [
      MyApp.Cat,
      MyApp.Dog
    ]
    algolia: [
      attributes_for_faceting: ["resource_type", "resource.kind"],
      searchable_attributes: ["resource.name", "resource.kind"],
      custom_ranking: ["desc(updated_at)"]
    ]

  def build_object(%MyApp.Cat{} = cat) do
    %{
      resource_type: "cat",
      resource: %{
        name: cat.name,
        kind: cat.kind,
        weigh: cat.weight
      }
    }
  end

  def build_object(%MyApp.Dog{} = dog) do
    %{
      resource_type: "dog",
      resource:  %{
        name: dog.name,
        kind: dog.kind,
        weigh: dog.weight
      }
    }
  end
end
```

Now you can just index your resources by using:

```elixir
# Reindex all
MyApp.GlobalIndex.reindex()

# Reindex only where dog or cat have name "Kitty" (why not for a dog)
MyApp.GlobalIndex.reindex(%{where: [name: "Kitty"]})

# Reindex only cat with name Kitty
import Ecto.Query
query = from(c in MyApp.Cat, where: c.name == "Kitty")
MyApp.GlobalIndex.reindex(query)

# Reindex all atomically
MyApp.GlobalIndex.reindex_atomic()
```
