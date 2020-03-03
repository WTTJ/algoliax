defmodule AlgoliaxTest.StructWithSecondaryIndexTest do
  use ExUnit.Case, async: true
  import Mox

  alias Algoliax.SettingsStore

  defmodule GlobalIndex do
    use Algoliax,
      index_name: :algoliax_global_index,
      attributes_for_faceting: ["resource_type"],
      searchable_attributes: ["resource.full_name"],
      custom_ranking: ["desc(updated_at)"],
      object_id: :reference
  end

  defmodule PeopleWithSecondaryIndex do
    use Algoliax,
      index_name: :algoliax_people_struct,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(updated_at)"],
      object_id: :reference,
      secondary_indexes: [
        GlobalIndex
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

    def to_be_indexed?(model) do
      model.age > 50
    end
  end

  setup do
    SettingsStore.set_settings(:algoliax_people_struct, %{})
    SettingsStore.set_settings(:algoliax_global_index, %{})
    :ok
  end

  test "save_object" do
    Algoliax.RequestsMock
    |> expect(
      :save_object,
      2,
      fn index,
         %{
           age: 77,
           first_name: "John",
           full_name: "John Doe",
           last_name: "Doe",
           nickname: "john",
           objectID: 10,
           updated_at: 1_546_300_800
         }
         when index in [:algoliax_people_struct, :algoliax_global_index] ->
        %{}
      end
    )

    person = %PeopleWithSecondaryIndex{
      reference: 10,
      last_name: "Doe",
      first_name: "John",
      age: 77
    }

    assert PeopleWithSecondaryIndex.save_object(person)
  end

  test "save_objects" do
    Algoliax.RequestsMock
    |> expect(
      :save_objects,
      2,
      fn index,
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
                 updated_at: 1_546_300_800
               }
             }
           ]
         }
         when index in [:algoliax_people_struct, :algoliax_global_index] ->
        %{}
      end
    )

    people = [
      %PeopleWithSecondaryIndex{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %PeopleWithSecondaryIndex{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]

    assert PeopleWithSecondaryIndex.save_objects(people)
  end

  test "delete_object" do
    Algoliax.RequestsMock
    |> expect(
      :delete_object,
      2,
      fn index,
         %{
           age: 77,
           first_name: "John",
           full_name: "John Doe",
           last_name: "Doe",
           nickname: "john",
           objectID: 10,
           updated_at: 1_546_300_800
         }
         when index in [:algoliax_people_struct, :algoliax_global_index] ->
        %{}
      end
    )

    person = %PeopleWithSecondaryIndex{
      reference: 10,
      last_name: "Doe",
      first_name: "John",
      age: 77
    }

    assert PeopleWithSecondaryIndex.delete_object(person)
  end
end
