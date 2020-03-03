defmodule AlgoliaxTest do
  use ExUnit.Case, async: true

  import Mox
  alias Algoliax.{People, SettingsStore}

  defmodule People do
    @moduledoc false

    use Algoliax,
      index_name: :algoliax_people,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"],
      object_id: :reference

    defstruct reference: nil, last_name: nil, first_name: nil, age: nil

    attributes([:first_name, :last_name])

    attribute(:age)

    attribute(:updated_at, Date.utc_today())

    attribute :full_name do
      Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
    end

    attribute :nickname do
      Map.get(model, :first_name, "") |> String.downcase()
    end
  end

  defmodule PeopleGreater50 do
    @moduledoc false

    use Algoliax,
      index_name: :algoliax_people,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"],
      object_id: :reference

    defstruct reference: nil, last_name: nil, first_name: nil, age: nil

    attributes([:first_name, :last_name])

    attribute(:age)

    attribute(:updated_at, Date.utc_today())

    attribute :full_name do
      Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
    end

    attribute :nickname do
      Map.get(model, :first_name, "") |> String.downcase()
    end

    @impl Algoliax
    def to_be_indexed?(model) do
      model.age > 50
    end
  end

  setup :verify_on_exit!

  setup do
    SettingsStore.set_settings(:algoliax_people, %{})
  end

  test "People has algoliax_attr_ functions" do
    [
      :algoliax_attr_age,
      :algoliax_attr_first_name,
      :algoliax_attr_full_name,
      :algoliax_attr_last_name,
      :algoliax_attr_nickname,
      :algoliax_attr_updated_at
    ]
    |> Enum.each(fn f ->
      assert f in Keyword.keys(People.__info__(:functions))
    end)
  end

  describe "All people" do
    test "People algolia_attr_ functions" do
      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20}

      assert People.algoliax_attr_age(people) == 20
      assert People.algoliax_attr_first_name(people) == "John"
      assert People.algoliax_attr_full_name(people) == "John Doe"
      assert People.algoliax_attr_last_name(people) == "Doe"
      assert People.algoliax_attr_nickname(people) == "john"
      assert People.algoliax_attr_updated_at(people) == Date.utc_today()
      assert People.to_be_indexed?(people)
    end

    test "save_object" do
      Algoliax.RequestsMock
      |> expect(:save_object, fn :algoliax_people,
                                 %{
                                   age: 20,
                                   first_name: "John",
                                   full_name: "John Doe",
                                   last_name: "Doe",
                                   nickname: "john",
                                   objectID: 10,
                                   updated_at: _
                                 } ->
        %{
          "updatedAt" => "2013-01-18T15:33:13.556Z",
          "taskID" => 679,
          "objectID" => "myID"
        }
      end)

      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20}

      assert %{
               "updatedAt" => "2013-01-18T15:33:13.556Z",
               "taskID" => 679,
               "objectID" => "myID"
             } == People.save_object(people)
    end

    test "save_objects" do
      Algoliax.RequestsMock
      |> expect(:save_objects, fn :algoliax_people,
                                  %{
                                    requests: [
                                      %{
                                        action: "updateObject",
                                        body: %{
                                          age: 20,
                                          first_name: "John",
                                          full_name: "John Doe",
                                          last_name: "Doe",
                                          nickname: "john",
                                          objectID: 10,
                                          updated_at: _
                                        }
                                      },
                                      %{
                                        action: "updateObject",
                                        body: %{
                                          age: 65,
                                          first_name: "Albert",
                                          full_name: "Albert Einstein",
                                          last_name: "Einstein",
                                          nickname: "albert",
                                          objectID: 89,
                                          updated_at: _
                                        }
                                      }
                                    ]
                                  } ->
        %{
          "taskID" => 792,
          "objectIDs" => ["89", "10"]
        }
      end)

      peoples = [
        %People{reference: 10, last_name: "Doe", first_name: "John", age: 20},
        %People{reference: 89, last_name: "Einstein", first_name: "Albert", age: 65}
      ]

      assert %{
               "taskID" => 792,
               "objectIDs" => ["89", "10"]
             } == People.save_objects(peoples)
    end
  end

  describe "People with age greater than 50" do
    test "People algolia_attr_ functions" do
      people = %PeopleGreater50{reference: 10, last_name: "Doe", first_name: "John", age: 20}

      assert PeopleGreater50.algoliax_attr_age(people) == 20
      assert PeopleGreater50.algoliax_attr_first_name(people) == "John"
      assert PeopleGreater50.algoliax_attr_full_name(people) == "John Doe"
      assert PeopleGreater50.algoliax_attr_last_name(people) == "Doe"
      assert PeopleGreater50.algoliax_attr_nickname(people) == "john"
      assert PeopleGreater50.algoliax_attr_updated_at(people) == Date.utc_today()
      refute PeopleGreater50.to_be_indexed?(people)
    end

    test "save_object" do
      Algoliax.RequestsMock
      |> expect(:save_object, 0, fn :algoliax_people, _ ->
        %{
          "updatedAt" => "2013-01-18T15:33:13.556Z",
          "taskID" => 679,
          "objectID" => "myID"
        }
      end)

      people = %PeopleGreater50{reference: 10, last_name: "Doe", first_name: "John", age: 20}

      assert {:not_indexable, people} == PeopleGreater50.save_object(people)
    end

    test "save_objects" do
      Algoliax.RequestsMock
      |> expect(:save_objects, fn :algoliax_people,
                                  %{
                                    requests: [
                                      %{
                                        action: "updateObject",
                                        body: %{
                                          age: 65,
                                          first_name: "Albert",
                                          full_name: "Albert Einstein",
                                          last_name: "Einstein",
                                          nickname: "albert",
                                          objectID: 89,
                                          updated_at: _
                                        }
                                      }
                                    ]
                                  } ->
        %{
          "taskID" => 792,
          "objectIDs" => ["89"]
        }
      end)

      peoples = [
        %PeopleGreater50{reference: 10, last_name: "Doe", first_name: "John", age: 20},
        %PeopleGreater50{reference: 89, last_name: "Einstein", first_name: "Albert", age: 65}
      ]

      assert %{
               "taskID" => 792,
               "objectIDs" => ["89"]
             } == PeopleGreater50.save_objects(peoples)
    end

    test "save_objects with force_delete" do
      Algoliax.RequestsMock
      |> expect(:save_objects, fn :algoliax_people,
                                  %{
                                    requests: [
                                      %{
                                        action: "deleteObject",
                                        body: %{
                                          age: 20,
                                          first_name: "John",
                                          full_name: "John Doe",
                                          last_name: "Doe",
                                          nickname: "john",
                                          objectID: 10,
                                          updated_at: _
                                        }
                                      },
                                      %{
                                        action: "updateObject",
                                        body: %{
                                          age: 65,
                                          first_name: "Albert",
                                          full_name: "Albert Einstein",
                                          last_name: "Einstein",
                                          nickname: "albert",
                                          objectID: 89,
                                          updated_at: _
                                        }
                                      }
                                    ]
                                  } ->
        %{
          "taskID" => 792,
          "objectIDs" => ["89", "10"]
        }
      end)

      peoples = [
        %PeopleGreater50{reference: 10, last_name: "Doe", first_name: "John", age: 20},
        %PeopleGreater50{reference: 89, last_name: "Einstein", first_name: "Albert", age: 65}
      ]

      assert %{
               "taskID" => 792,
               "objectIDs" => ["89", "10"]
             } == PeopleGreater50.save_objects(peoples, force_delete: true)
    end
  end

  test "generate secured api key" do
    Application.put_env(:algoliax, :api_key, "api_key")
    assert Algoliax.generate_secured_api_key("reference:10")
  end
end
