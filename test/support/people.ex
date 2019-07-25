defmodule Algoliax.People do
  use Algoliax,
    index_name: :algoliax_people,
    attributes_for_faceting: ["age"],
    searchable_attributes: ["full_name"],
    custom_ranking: ["desc(update_at)"],
    object_id: :reference

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  attributes([:first_name, :last_name, :age])

  attribute(:updated_at, Date.utc_today())

  attribute :full_name do
    Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
  end

  attribute :nickname do
    Map.get(model, :first_name, "") |> String.downcase()
  end
end
