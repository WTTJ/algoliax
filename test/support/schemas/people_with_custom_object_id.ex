defmodule Algoliax.Schemas.PeopleWithCustomObjectId do
  @moduledoc false

  use Ecto.Schema

  use Algoliax.Indexer,
    index_name: :algoliax_people_with_custom_object_id,
    repo: Algoliax.Repo,
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

  def build_object(people) do
    %{
      last_name: people.last_name
    }
  end

  def get_object_id(people) do
    "people-" <> people.reference
  end
end
