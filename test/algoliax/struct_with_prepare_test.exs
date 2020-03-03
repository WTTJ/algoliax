defmodule AlgoliaxTest.StructWithPrepareTest do
  use ExUnit.Case, async: true
  import Mox

  alias Algoliax.SettingsStore

  defmodule PeopleWithPrepareObject do
    use Algoliax,
      index_name: :algoliax_people_with_prepare_object_struct,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"],
      object_id: :reference,
      prepare_object: &__MODULE__.prepare/2

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

  setup do
    SettingsStore.set_settings(:algoliax_people_with_prepare_object_struct, %{})
    :ok
  end

  test "save_object" do
    Algoliax.RequestsMock
    |> expect(:save_object, fn :algoliax_people_with_prepare_object_struct,
                               %{
                                 age: 77,
                                 first_name: "John",
                                 full_name: "John Doe",
                                 last_name: "Doe",
                                 nickname: "john",
                                 objectID: 10,
                                 updated_at: 1_546_300_800,
                                 prepared: true
                               } ->
      %{}
    end)

    person = %PeopleWithPrepareObject{
      reference: 10,
      last_name: "Doe",
      first_name: "John",
      age: 77
    }

    assert PeopleWithPrepareObject.save_object(person)
  end

  test "save_objects" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people_with_prepare_object_struct,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 77,
                                        first_name: "John",
                                        full_name: "John Doe",
                                        last_name: "Doe",
                                        nickname: "john",
                                        objectID: 10,
                                        updated_at: 1_546_300_800,
                                        prepared: true
                                      }
                                    }
                                  ]
                                } ->
      %{}
    end)

    people = [
      %PeopleWithPrepareObject{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %PeopleWithPrepareObject{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]

    assert PeopleWithPrepareObject.save_objects(people)
  end
end
