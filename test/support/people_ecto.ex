defmodule Algoliax.PeopleEcto do
  use Ecto.Schema

  use Algoliax,
    index_name: :algoliax_people,
    attribute_for_faceting: ["age"],
    custom_ranking: ["desc(update_at)"],
    repo: Algoliax.Repo,
    object_id: :reference

  schema "peoples" do
    field(:reference, :integer)
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
  end

  # defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  attributes([:first_name, :last_name, :age])

  attribute(:updated_at, DateTime.utc_now() |> DateTime.to_unix())

  attribute :full_name do
    Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
  end

  attribute :nickname do
    Map.get(model, :first_name, "") |> String.downcase()
  end
end
