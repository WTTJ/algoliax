defmodule AlgoliaxTest.Struct do
  use ExUnit.Case, async: true
  doctest Algoliax
  import Mox

  defmodule People do
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

    def to_be_indexed?(model) do
      model.age > 50
    end
  end

  test "save_object" do
    Algoliax.RequestsMock
    |> expect(:save_object, fn _, _ ->
      %{}
    end)

    person = %People{reference: 10, last_name: "Doe", first_name: "John", age: 77}

    assert People.save_object(person)
  end

  test "save_objects" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn _, _ ->
      %{}
    end)

    people = [
      %People{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %People{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]

    assert People.save_objects(people)
  end

  test "get_object" do
    Algoliax.RequestsMock
    |> expect(:get_object, fn _, _ ->
      %{}
    end)

    p = %People{reference: 10, last_name: "Doe", first_name: "John", age: 77}
    assert People.get_object(p)
  end

  test "delete_object" do
    Algoliax.RequestsMock
    |> expect(:delete_object, fn _, _ ->
      %{}
    end)

    p = %People{reference: 10, last_name: "Doe", first_name: "John", age: 77}
    assert People.delete_object(p)
  end

  test "reindex" do
    assert_raise(Algoliax.MissingRepoError, fn -> People.reindex() end)
  end
end
