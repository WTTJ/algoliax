defmodule Algoliax.Schemas.PeopleEctoWithAssociation do
  @moduledoc false

  use Ecto.Schema

  use Algoliax,
    index_name: :algoliax_people_ecto_with_association,
    attributes_for_faceting: ["age", "gender"],
    searchable_attributes: ["full_name", "gender"],
    custom_ranking: ["desc(updated_at)"],
    repo: Algoliax.Repo,
    object_id: :reference,
    preloads: [:animals]

  schema "peoples_ecto_with_association" do
    field(:reference, Ecto.UUID)
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)
    has_many(:animals, Algoliax.Schemas.Animal)

    timestamps()
  end

  attributes([:id, :first_name, :last_name, :age, :gender])

  attribute(:updated_at, ~U[2019-01-01 00:00:00Z] |> DateTime.to_unix())

  attribute(:animals) do
    Enum.map(model.animals, fn a ->
      a.kind
    end)
  end

  attribute :full_name do
    Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
  end

  attribute :nickname do
    Map.get(model, :first_name, "") |> String.downcase()
  end
end
