defmodule Algoliax.PeopleEcto do
  @moduledoc false

  use Ecto.Schema

  use Algoliax,
    index_name: :algoliax_people,
    attributes_for_faceting: ["age", "gender"],
    searchable_attributes: ["full_name", "gender"],
    custom_ranking: ["desc(update_at)"],
    repo: Algoliax.Repo,
    object_id: :reference

  schema "peoples" do
    field(:reference, Ecto.UUID)
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)

    timestamps()
  end

  # defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  attributes([:first_name, :last_name, :age, :gender])

  attribute(:updated_at, DateTime.utc_now() |> DateTime.to_unix())

  attribute :full_name do
    Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
  end

  attribute :nickname do
    Map.get(model, :first_name, "") |> String.downcase()
  end
end
