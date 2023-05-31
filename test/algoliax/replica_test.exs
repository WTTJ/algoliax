defmodule AlgoliaxTest.ReplicaTest do
  use Algoliax.RequestCase

  alias Algoliax.Schemas.PeopleWithReplicas
  alias Algoliax.Schemas.PeopleWithReplicasMultipleIndexes

  setup do
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas_en, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas_fr, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas_asc, %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_replicas_desc, %{})
    :ok
  end

  describe "replica" do
    test "configure_index/0" do
      assert {:ok, res} = PeopleWithReplicas.configure_index()
      assert %Algoliax.Response{response: %{"taskID" => _, "updatedAt" => _}} = res

      assert_request("PUT", ~r/algoliax_people_replicas/, %{
        "searchableAttributes" => ["full_name"],
        "attributesForFaceting" => ["age"],
        "replicas" => ["algoliax_people_replicas_asc", "algoliax_people_replicas_desc"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_asc/, %{
        "searchableAttributes" => ["age"],
        "attributesForFaceting" => ["age"],
        "ranking" => ["asc(age)"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_desc/, %{
        "searchableAttributes" => nil,
        "attributesForFaceting" => nil,
        "ranking" => ["desc(age)"]
      })
    end

    test "configure_index/0 with multiple indexes" do
      assert [{:ok, res}, {:ok, res2}] = PeopleWithReplicasMultipleIndexes.configure_index()

      assert %Algoliax.Response{
               response: %{"taskID" => _, "updatedAt" => _},
               params: [index_name: :algoliax_people_replicas_en]
             } = res

      assert %Algoliax.Response{
               response: %{"taskID" => _, "updatedAt" => _},
               params: [index_name: :algoliax_people_replicas_fr]
             } = res2

      assert_request("PUT", ~r/algoliax_people_replicas_en/, %{
        "searchableAttributes" => ["full_name"],
        "attributesForFaceting" => ["age"],
        "replicas" => ["algoliax_people_replicas_asc_en", "algoliax_people_replicas_desc_en"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_fr/, %{
        "searchableAttributes" => ["full_name"],
        "attributesForFaceting" => ["age"],
        "replicas" => ["algoliax_people_replicas_asc_fr", "algoliax_people_replicas_desc_fr"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_asc_en/, %{
        "searchableAttributes" => ["age"],
        "attributesForFaceting" => ["age"],
        "ranking" => ["asc(age)"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_asc_fr/, %{
        "searchableAttributes" => ["age"],
        "attributesForFaceting" => ["age"],
        "ranking" => ["asc(age)"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_desc_en/, %{
        "searchableAttributes" => nil,
        "attributesForFaceting" => nil,
        "ranking" => ["desc(age)"]
      })

      assert_request("PUT", ~r/algoliax_people_replicas_desc_fr/, %{
        "searchableAttributes" => nil,
        "attributesForFaceting" => nil,
        "ranking" => ["desc(age)"]
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
        "age" => 77,
        "first_name" => "John",
        "full_name" => "John Doe",
        "last_name" => "Doe",
        "nickname" => "john",
        "objectID" => reference,
        "updated_at" => 1_546_300_800
      })
    end

    test "save_object/1 with multiple indexes" do
      reference = :rand.uniform(1_000_000) |> to_string()

      person = %PeopleWithReplicasMultipleIndexes{
        reference: reference,
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert [{:ok, res}, {:ok, res2}] = PeopleWithReplicasMultipleIndexes.save_object(person)

      assert %Algoliax.Response{
               response: %{"taskID" => _, "updatedAt" => _, "objectID" => ^reference},
               params: [index_name: :algoliax_people_replicas_en, object_id: ^reference]
             } = res

      assert %Algoliax.Response{
               response: %{"taskID" => _, "updatedAt" => _, "objectID" => ^reference},
               params: [index_name: :algoliax_people_replicas_fr, object_id: ^reference]
             } = res2

      assert_request("PUT", ~r/algoliax_people_replicas_en/, %{
        "age" => 77,
        "first_name" => "John",
        "full_name" => "John Doe",
        "last_name" => "Doe",
        "nickname" => "john",
        "objectID" => reference,
        "updated_at" => 1_546_300_800
      })

      assert_request("PUT", ~r/algoliax_people_replicas_fr/, %{
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
        "requests" => [
          %{"action" => "updateObject", "body" => %{"objectID" => reference1}},
          %{"action" => "updateObject", "body" => %{"objectID" => reference2}}
        ]
      })
    end

    test "save_objects/1 with multiple indexes" do
      reference1 = :rand.uniform(1_000_000) |> to_string()
      reference2 = :rand.uniform(1_000_000) |> to_string()

      people = [
        %PeopleWithReplicasMultipleIndexes{
          reference: reference1,
          last_name: "Doe",
          first_name: "John",
          age: 77
        },
        %PeopleWithReplicasMultipleIndexes{
          reference: reference2,
          last_name: "al",
          first_name: "bert",
          age: 35
        }
      ]

      assert [{:ok, res}, {:ok, res2}] = PeopleWithReplicasMultipleIndexes.save_objects(people)

      assert %Algoliax.Response{
               response: %{
                 "taskID" => _,
                 "objectIDs" => [^reference1, ^reference2]
               },
               params: [index_name: :algoliax_people_replicas_en]
             } = res

      assert %Algoliax.Response{
               response: %{
                 "taskID" => _,
                 "objectIDs" => [^reference1, ^reference2]
               },
               params: [index_name: :algoliax_people_replicas_fr]
             } = res2

      assert_request("POST", ~r/algoliax_people_replicas_en/, %{
        "requests" => [
          %{"action" => "updateObject", "body" => %{"objectID" => reference1}},
          %{"action" => "updateObject", "body" => %{"objectID" => reference2}}
        ]
      })

      assert_request("POST", ~r/algoliax_people_replicas_fr/, %{
        "requests" => [
          %{"action" => "updateObject", "body" => %{"objectID" => reference1}},
          %{"action" => "updateObject", "body" => %{"objectID" => reference2}}
        ]
      })
    end

    test "get_object/1 " do
      person = %PeopleWithReplicas{
        reference: "known",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:ok, res} = PeopleWithReplicas.get_object(person)
      assert %Algoliax.Response{response: %{"objectID" => "known"}} = res
      assert_request("GET", %{})
    end

    test "get_object/1 with multiple indexes" do
      person = %PeopleWithReplicasMultipleIndexes{
        reference: "known",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert [{:ok, res}, {:ok, res2}] = PeopleWithReplicasMultipleIndexes.get_object(person)

      assert %Algoliax.Response{
               response: %{"objectID" => "known"},
               params: [index_name: :algoliax_people_replicas_en, object_id: "known"]
             } = res

      assert %Algoliax.Response{
               response: %{"objectID" => "known"},
               params: [index_name: :algoliax_people_replicas_fr, object_id: "known"]
             } = res2

      assert_request("GET", ~r/algoliax_people_replicas_en/, %{})
      assert_request("GET", ~r/algoliax_people_replicas_fr/, %{})
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

    test "get_object/1 w/ unknown & multiple indexes" do
      person = %PeopleWithReplicasMultipleIndexes{
        reference: "unknown",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert [{:error, 404, _}, {:error, 404, _}] =
               PeopleWithReplicasMultipleIndexes.get_object(person)

      assert_request("GET", ~r/algoliax_people_replicas_en/, %{})
      assert_request("GET", ~r/algoliax_people_replicas_fr/, %{})
    end

    test "delete_object/1" do
      person = %PeopleWithReplicas{
        reference: "unknown",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert {:ok, _} = PeopleWithReplicas.delete_object(person)
      assert_request("DELETE", %{})
    end

    test "delete_object/1 with multiple indexes" do
      person = %PeopleWithReplicasMultipleIndexes{
        reference: "unknown",
        last_name: "Doe",
        first_name: "John",
        age: 77
      }

      assert [{:ok, _}, {:ok, _}] = PeopleWithReplicasMultipleIndexes.delete_object(person)
      assert_request("DELETE", ~r/algoliax_people_replicas_en/, %{})
      assert_request("DELETE", ~r/algoliax_people_replicas_fr/, %{})
    end

    test "delete_index/0" do
      assert {:ok, _} = PeopleWithReplicas.delete_index()
      assert_request("DELETE", %{})
    end

    test "delete_index/0 with multiple indexes" do
      assert [{:ok, _}, {:ok, _}] = PeopleWithReplicasMultipleIndexes.delete_index()
      assert_request("DELETE", ~r/algoliax_people_replicas_en/, %{})
      assert_request("DELETE", ~r/algoliax_people_replicas_fr/, %{})
    end

    test "get_settings/0" do
      assert {:ok, res} = PeopleWithReplicas.get_settings()
      assert %Algoliax.Response{response: %{"searchableAttributes" => ["test"]}} = res
      assert_request("GET", %{})
    end

    test "get_settings/0 with multiple indexes" do
      assert [{:ok, res}, {:ok, res2}] = PeopleWithReplicasMultipleIndexes.get_settings()

      assert %Algoliax.Response{
               response: %{"searchableAttributes" => ["test"]},
               params: [index_name: :algoliax_people_replicas_en]
             } = res

      assert %Algoliax.Response{
               response: %{"searchableAttributes" => ["test"]},
               params: [index_name: :algoliax_people_replicas_fr]
             } = res2

      assert_request("GET", ~r/algoliax_people_replicas_en/, %{})
      assert_request("GET", ~r/algoliax_people_replicas_fr/, %{})
    end

    test "search/2" do
      assert {:ok, _} = PeopleWithReplicas.search("john", %{hitsPerPage: 10})
      assert_request("POST", %{"query" => "john", "hitsPerPage" => 10})
    end

    test "search/2 with multiple indexes" do
      assert [{:ok, _}, {:ok, _}] =
               PeopleWithReplicasMultipleIndexes.search("john", %{hitsPerPage: 10})

      assert_request("POST", ~r/algoliax_people_replicas_en/, %{
        "query" => "john",
        "hitsPerPage" => 10
      })

      assert_request("POST", ~r/algoliax_people_replicas_fr/, %{
        "query" => "john",
        "hitsPerPage" => 10
      })
    end

    test "search_facet/2" do
      assert {:ok, _} = PeopleWithReplicas.search_facet("age", "2")
      assert_request("POST", %{"facetQuery" => "2"})
    end

    test "search_facet/2 with multiple indexes" do
      assert [{:ok, _}, {:ok, _}] = PeopleWithReplicasMultipleIndexes.search_facet("age", "2")
      assert_request("POST", ~r/algoliax_people_replicas_en/, %{"facetQuery" => "2"})
      assert_request("POST", ~r/algoliax_people_replicas_fr/, %{"facetQuery" => "2"})
    end
  end
end
