defmodule AlgoliaxTest.Struct do
  use ExUnit.Case, async: true
  doctest Algoliax

  defmodule People do
    use Ecto.Schema

    use Algoliax,
      index_name: :algoliax_people,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"],
      object_id: :reference

    defstruct reference: nil, last_name: nil, first_name: nil, age: nil

    attributes([:first_name, :last_name, :age])

    attribute(:updated_at, DateTime.utc_now() |> DateTime.to_unix())

    attribute :full_name do
      Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
    end

    attribute :nickname do
      Map.get(model, :first_name, "") |> String.downcase()
    end
  end

  test "save_object" do
    people = [
      %People{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %People{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]
  end
end
