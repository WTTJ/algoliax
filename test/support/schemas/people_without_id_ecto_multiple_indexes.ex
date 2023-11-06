defmodule Algoliax.Schemas.PeopleWithoutIdEctoMultipleIndexes do
  @moduledoc false

  use Ecto.Schema

  use Algoliax.Indexer,
    index_name: [:algoliax_people_without_id_en, :algoliax_people_without_id_fr],
    repo: Algoliax.Repo,
    object_id: :reference,
    cursor_field: :inserted_at,
    algolia: [
      attributes_for_faceting: ["age", "gender"],
      searchable_attributes: ["firstname", "lastname"],
      custom_ranking: ["desc(updated_at)"]
    ]

  @primary_key {:reference, Ecto.UUID, autogenerate: true}
  schema "peoples_without_id" do
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)

    timestamps()
  end
end
