defmodule Algoliax.Schemas.PeopleWithSchemasMultipleIndexes do
  @moduledoc false

  use Ecto.Schema

  alias Algoliax.Schemas.Beer

  use Algoliax.Indexer,
    index_name: [:algoliax_with_schemas_en, :algoliax_with_schemas_fr],
    repo: Algoliax.Repo,
    schemas: [
      Beer
    ],
    algolia: [
      attributes_for_faceting: ["age", "gender"],
      searchable_attributes: ["full_name", "gender"],
      custom_ranking: ["desc(updated_at)"]
    ]

  schema "peoples" do
    field(:reference, Ecto.UUID)
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)

    timestamps()
  end

  def build_object(%Beer{} = beer) do
    %{
      name: beer.name
    }
  end
end
