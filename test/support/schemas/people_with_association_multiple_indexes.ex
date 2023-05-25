defmodule Algoliax.Schemas.PeopleWithAssociationMultipleIndexes do
  @moduledoc false

  use Ecto.Schema

  use Algoliax.Indexer,
    index_name: [
      :algoliax_people_ecto_with_association_en,
      :algoliax_people_ecto_with_association_fr
    ],
    repo: Algoliax.Repo,
    object_id: :reference,
    schemas: [
      {__MODULE__, [:flowers]}
    ],
    algolia: [
      attributes_for_faceting: ["age", "gender"],
      searchable_attributes: ["full_name", "gender"],
      custom_ranking: ["desc(updated_at)"]
    ]

  schema "peoples_with_associations_multiple_indexes" do
    field(:reference, Ecto.UUID)
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)
    has_many(:flowers, Algoliax.Schemas.Flower)

    timestamps()
  end

  def build_object(people) do
    %{
      flowers:
        Enum.map(people.flowers, fn flower ->
          %{
            kind: flower.kind
          }
        end)
    }
  end
end
