defmodule Algoliax.Schemas.PeopleStructWithPrepareObject do
  @moduledoc false

  use Algoliax.Indexer,
    index_name: :algoliax_people_with_prepare_object_struct,
    object_id: :reference,
    prepare_object: &__MODULE__.prepare/2,
    algolia: [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"]
    ]

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  attributes([:first_name, :last_name, :age])

  attribute(:updated_at, ~U[2019-01-01 00:00:00Z] |> DateTime.to_unix())

  attribute :full_name do
    Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
  end

  attribute :nickname do
    Map.get(model, :first_name, "") |> String.downcase()
  end

  def prepare(object, _) do
    object
    |> Map.put(:prepared, true)
  end

  def to_be_indexed?(model) do
    model.age > 50
  end
end
