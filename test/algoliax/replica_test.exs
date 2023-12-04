defmodule AlgoliaxTest.ReplicaTest do
  use Algoliax.RequestCase

  alias Algoliax.Schemas.PeopleWithReplicas

  setup do
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas_asc, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas_desc, %{})
    :ok
  end

  describe "replica" do
    test "configure_index/0" do
      assert {:ok, res} = PeopleWithReplicas.configure_index()
      assert %Algoliax.Response{response: %{"taskID" => _, "updatedAt" => _}} = res

      assert_request("PUT", %{
        path: ~r/algoliax_people_replicas/,
        body: %{
          "searchableAttributes" => ["full_name"],
          "attributesForFaceting" => ["age"],
          "replicas" => ["algoliax_people_replicas_asc", "algoliax_people_replicas_desc"]
        }
      })

      assert_request("PUT", %{
        path: ~r/algoliax_people_replicas_asc/,
        body: %{
          "searchableAttributes" => ["age"],
          "attributesForFaceting" => ["age"],
          "ranking" => ["asc(age)"]
        }
      })

      assert_request("PUT", %{
        path: ~r/algoliax_people_replicas_desc/,
        body: %{
          "searchableAttributes" => nil,
          "attributesForFaceting" => nil,
          "ranking" => ["desc(age)"]
        }
      })
    end

    test "save_object/1" do
      reference = :rand.uniform(1_000_000) |> to_string()

      person = %PeopleWithReplicas{
        reference: reference,
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:ok, res} = PeopleWithReplicas.save_object(person)

      assert %Algoliax.Response{
               response: %{"taskID" => _, "updatedAt" => _, "objectID" => ^reference}
             } = res

      assert_request("PUT", %{
        body: %{
          "age" => 77,
          "first_name" => "John",
          "full_name" => "John Doe",
          "last_name" => "Doe",
          "nickname" => "john",
          "objectID" => reference,
          "updated_at" => 1_546_300_800
        }
      })
    end

    test "save_objects/1" do
      reference1 = :rand.uniform(1_000_000) |> to_string()
      reference2 = :rand.uniform(1_000_000) |> to_string()

      people = [
        %PeopleWithReplicas{reference: reference1, last_name: "Doe", first_name: "John", age: 77},
        %PeopleWithReplicas{reference: reference2, last_name: "al", first_name: "bert", age: 35}
      ]

      assert {:ok, res} = PeopleWithReplicas.save_objects(people)

      assert %Algoliax.Response{
               response: %{
                 "taskID" => _,
                 "objectIDs" => [reference1, reference2]
               }
             } = res

      assert_request("POST", %{
        body: %{
          "requests" => [
            %{"action" => "updateObject", "body" => %{"objectID" => reference1}},
            %{"action" => "updateObject", "body" => %{"objectID" => reference2}}
          ]
        }
      })
    end

    test "get_object/1" do
      person = %PeopleWithReplicas{
        reference: "known",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:ok, res} = PeopleWithReplicas.get_object(person)
      assert %Algoliax.Response{response: %{"objectID" => "known"}} = res
      assert_request("GET", %{body: %{}})
    end

    test "get_object/1 w/ unknown" do
      person = %PeopleWithReplicas{
        reference: "unknown",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:error, 404, _} = PeopleWithReplicas.get_object(person)
    end

    test "delete_object/1" do
      person = %PeopleWithReplicas{
        reference: "unknown",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:ok, _} = PeopleWithReplicas.delete_object(person)
      assert_request("DELETE", %{body: %{}})
    end

    test "delete_index/0" do
      assert {:ok, _} = PeopleWithReplicas.delete_index()
      assert_request("DELETE", %{body: %{}})
    end

    test "get_settings/0" do
      assert {:ok, res} = PeopleWithReplicas.get_settings()
      assert %Algoliax.Response{response: %{"searchableAttributes" => ["test"]}} = res
      assert_request("GET", %{body: %{}})
    end

    test "search/2" do
      assert {:ok, _} = PeopleWithReplicas.search("john", %{hitsPerPage: 10})
      assert_request("POST", %{body: %{"query" => "john", "hitsPerPage" => 10}})
    end

    test "search_facet/2" do
      assert {:ok, _} = PeopleWithReplicas.search_facet("age", "2")
      assert_request("POST", %{body: %{"facetQuery" => "2"}})
    end
  end
end
