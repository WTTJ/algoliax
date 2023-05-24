defmodule AlgoliaxTest.StructTest do
  use Algoliax.RequestCase

  alias Algoliax.Schemas.{
    PeopleStruct,
    PeopleStructRuntimeIndexName,
    PeopleStructWithAdditionalIndexes
  }

  setup do
    Algoliax.SettingsStore.set_settings(:algoliax_people_struct, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_with_prepare_object_struct, %{})
    :ok
  end

  describe "basic struct" do
    test "configure_index/0" do
      assert {:ok, res} = PeopleStruct.configure_index()
      assert %Algoliax.Response{response: %{"taskID" => _, "updatedAt" => _}} = res

      assert_request("PUT", %{
        "searchableAttributes" => ["full_name"],
        "attributesForFaceting" => ["age"]
      })
    end

    test "save_object/1" do
      reference = :random.uniform(1_000_000) |> to_string()
      person = %PeopleStruct{reference: reference, last_name: "Doe", first_name: "John", age: 77}
      assert {:ok, res} = PeopleStruct.save_object(person)

      assert %Algoliax.Response{
               response: %{"objectID" => ^reference, "taskID" => _, "updatedAt" => _}
             } = res

      assert_request("PUT", %{
        "age" => 77,
        "first_name" => "John",
        "full_name" => "John Doe",
        "last_name" => "Doe",
        "nickname" => "john",
        "objectID" => reference,
        "updated_at" => 1_546_300_800
      })
    end

    test "save_objects/1" do
      reference1 = :random.uniform(1_000_000) |> to_string()
      reference2 = :random.uniform(1_000_000) |> to_string()

      people = [
        %PeopleStruct{reference: reference1, last_name: "Doe", first_name: "John", age: 77},
        %PeopleStruct{reference: reference2, last_name: "al", first_name: "bert", age: 35}
      ]

      assert {:ok, res} = PeopleStruct.save_objects(people)

      assert %Algoliax.Response{
               response: %{"taskID" => _, "objectIDs" => [reference1]}
             } = res

      assert_request("POST", %{
        "requests" => [%{"action" => "updateObject", "body" => %{"objectID" => reference1}}]
      })
    end

    test "save_objects/1 w/ force_delete: true" do
      reference1 = :random.uniform(1_000_000) |> to_string()
      reference2 = :random.uniform(1_000_000) |> to_string()

      people = [
        %PeopleStruct{reference: reference1, last_name: "Doe", first_name: "John", age: 77},
        %PeopleStruct{reference: reference2, last_name: "al", first_name: "bert", age: 35}
      ]

      assert {:ok, res} = PeopleStruct.save_objects(people, force_delete: true)

      assert %Algoliax.Response{
               response: %{"taskID" => _, "objectIDs" => [reference1, reference2]}
             } = res

      assert_request("POST", %{
        "requests" => [
          %{"action" => "updateObject", "body" => %{"objectID" => reference1}},
          %{"action" => "deleteObject", "body" => %{"objectID" => reference2}}
        ]
      })
    end

    test "get_object/1" do
      person = %PeopleStruct{reference: "known", last_name: "Doe", first_name: "John", age: 77}
      assert {:ok, res} = PeopleStruct.get_object(person)
      assert %Algoliax.Response{response: %{"objectID" => "known"}} = res
      assert_request("GET", %{})
    end

    test "get_object/1 w/ unknown" do
      person = %PeopleStruct{reference: "unknown", last_name: "Doe", first_name: "John", age: 77}
      assert {:error, 404, _} = PeopleStruct.get_object(person)
    end

    test "delete_object/1" do
      person = %PeopleStruct{reference: "unknown", last_name: "Doe", first_name: "John", age: 77}
      assert {:ok, _} = PeopleStruct.delete_object(person)
      assert_request("DELETE", %{})
    end

    test "reindex/0" do
      assert_raise(Algoliax.MissingRepoError, fn -> PeopleStruct.reindex() end)
    end

    test "delete_index/0" do
      assert {:ok, _} = PeopleStruct.delete_index()
      assert_request("DELETE", %{})
    end

    test "get_settings/0" do
      assert {:ok, res} = PeopleStruct.get_settings()
      assert %Algoliax.Response{response: %{"searchableAttributes" => ["test"]}} = res
      assert_request("GET", %{})
    end

    test "search/2" do
      assert {:ok, _} = PeopleStruct.search("john", %{hitsPerPage: 10})
      assert_request("POST", %{"query" => "john", "hitsPerPage" => 10})
    end

    test "search_facet/2" do
      assert {:ok, _} = PeopleStruct.search_facet("age", "2")
      assert_request("POST", %{"facetQuery" => "2"})
    end

    test "delete_by/1" do
      assert {:ok, res} = PeopleStruct.delete_by("age > 18")
      assert_request("POST", %{"params" => "filters=age > 18"})

      assert %Algoliax.Response{
               response: %{"taskID" => _, "updatedAt" => _}
             } = res
    end
  end

  describe "runtime index name" do
    test "get_object/1" do
      person = %PeopleStructRuntimeIndexName{
        reference: "known",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:ok, res} = PeopleStructRuntimeIndexName.get_object(person)
      assert %Algoliax.Response{response: %{"objectID" => "known"}} = res
      assert_request("PUT", ~r/people_runtime_index_name\/settings/, %{})
      assert_request("GET", ~r/people_runtime_index_name\/settings/, %{})
      assert_request("GET", ~r/people_runtime_index_name\/known/, %{})
    end
  end

  describe "wait for task" do
    reference = :random.uniform(1_000_000) |> to_string()
    person = %PeopleStruct{reference: reference, last_name: "Doe", first_name: "John", age: 77}
    assert {:ok, res} = PeopleStruct.save_object(person) |> Algoliax.wait_task()

    assert %Algoliax.Response{
             response: %{"objectID" => ^reference, "taskID" => task_id, "updatedAt" => _}
           } = res

    # Assert that there are 4 calls to check task status
    assert_request("GET", ~r/algoliax_people_struct\/task\/#{task_id}/, %{})
    assert_request("GET", ~r/algoliax_people_struct\/task\/#{task_id}/, %{})
    assert_request("GET", ~r/algoliax_people_struct\/task\/#{task_id}/, %{})
    assert_request("GET", ~r/algoliax_people_struct\/task\/#{task_id}/, %{})
  end
end
