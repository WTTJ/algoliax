defmodule AlgoliaxTest.Struct do
  use ExUnit.Case, async: true
  import Mox

  defmodule People do
    use Algoliax,
      index_name: :algoliax_people_struct,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"],
      object_id: :reference

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
    Algoliax.Agent.set_settings(:algoliax_people_struct, %{})
    :ok
  end

  test "configure index" do
    Algoliax.RequestsMock
    |> expect(:configure_index, fn :algoliax_people_struct, _ ->
      %{}
    end)

    assert People.configure_index()
  end

  test "save_object" do
    Algoliax.RequestsMock
    |> expect(:save_object, fn :algoliax_people_struct,
                               %{
                                 age: 77,
                                 first_name: "John",
                                 full_name: "John Doe",
                                 last_name: "Doe",
                                 nickname: "john",
                                 objectID: 10,
                                 updated_at: 1_546_300_800
                               } ->
      %{}
    end)

    person = %People{reference: 10, last_name: "Doe", first_name: "John", age: 77}

    assert People.save_object(person)
  end

  test "save_objects" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people_struct,
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
                                } ->
      %{}
    end)

    people = [
      %People{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %People{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]

    assert People.save_objects(people)
  end

  test "save_objects with force delete" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people_struct,
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
                                    },
                                    %{
                                      action: "deleteObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        full_name: "bert al",
                                        last_name: "al",
                                        nickname: "bert",
                                        objectID: 87,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{}
    end)

    people = [
      %People{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %People{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]

    assert People.save_objects(people, force_delete: true)
  end

  test "get_object" do
    Algoliax.RequestsMock
    |> expect(:get_object, fn :algoliax_people_struct,
                              %{
                                objectID: 10
                              } ->
      %{}
    end)

    p = %People{reference: 10, last_name: "Doe", first_name: "John", age: 77}
    assert People.get_object(p)
  end

  test "delete_object" do
    Algoliax.RequestsMock
    |> expect(:delete_object, fn :algoliax_people_struct,
                                 %{
                                   objectID: 10
                                 } ->
      %{}
    end)

    p = %People{reference: 10, last_name: "Doe", first_name: "John", age: 77}
    assert People.delete_object(p)
  end

  test "reindex" do
    assert_raise(Algoliax.MissingRepoError, fn -> People.reindex() end)
  end

  test "delete index" do
    Algoliax.RequestsMock
    |> expect(:delete_index, fn :algoliax_people_struct ->
      %{}
    end)

    assert People.delete_index()
  end

  test "get index settings" do
    Algoliax.RequestsMock
    |> expect(:get_settings, fn :algoliax_people_struct ->
      %{}
    end)

    assert People.get_settings()
  end

  test "search in index" do
    Algoliax.RequestsMock
    |> expect(:search, fn :algoliax_people_struct, %{query: "john"} ->
      %{}
    end)

    assert People.search("john")
  end

  test "search facet" do
    Algoliax.RequestsMock
    |> expect(:search_facet, fn :algoliax_people_struct, "age", %{} ->
      %{}
    end)

    assert People.search_facet("age")
  end
end
