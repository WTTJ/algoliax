defmodule Algoliax.Schemas.PeopleWithAssociation do
  @moduledoc false

  use Ecto.Schema

  use Algoliax.Indexer,
    index_name: :algoliax_people_ecto_with_association,
    repo: Algoliax.Repo,
    object_id: :reference,
    schemas: [
      {__MODULE__, [:animals]}
    ],
    algolia: [
      attributes_for_faceting: ["age", "gender"],
      searchable_attributes: ["full_name", "gender"],
      custom_ranking: ["desc(updated_at)"]
    ]

  schema "peoples_with_associations" do
    field(:reference, Ecto.UUID)
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)
    has_many(:animals, Algoliax.Schemas.Animal)

    timestamps()
  end

  def build_object(people) do
    %{
      animals:
        Enum.map(people.animals, fn animal ->
          %{
            kind: animal.kind
          }
        end)
    }
  end
end
