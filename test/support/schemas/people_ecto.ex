defmodule Algoliax.Schemas.PeopleEcto do
  @moduledoc false

  use Ecto.Schema

  use Algoliax.Indexer,
    index_name: :algoliax_people,
    repo: Algoliax.Repo,
    object_id: :reference,
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
      first_name: people.first_name,
      last_name: people.last_name,
      age: people.age,
      updated_at: ~U[2019-01-01 00:00:00Z] |> DateTime.to_unix(),
      full_name: Map.get(people, :first_name, "") <> " " <> Map.get(people, :last_name, ""),
      nickname: Map.get(people, :first_name, "") |> String.downcase()
    }
  end

  def to_be_indexed?(people) do
    people.age > 10
  end
end
