# defmodule Algoliax.SchemaTest do
#   use Algoliax.RequestCase

#   import Ecto.Query
#   alias Algoliax.PeopleEcto
# end

defmodule AlgoliaxTest.Schema do
  use Algoliax.RequestCase
  import Ecto.Query

  alias Algoliax.Repo

  alias Algoliax.Schemas.{
    Animal,
    Beer,
    Flower,
    PeopleEcto,
    PeopleEctoMultipleIndexes,
    PeopleEctoFail,
    PeopleEctoFailMultipleIndexes,
    PeopleWithoutIdEcto,
    PeopleWithoutIdEctoMultipleIndexes,
    PeopleWithSchemas,
    PeopleWithSchemasMultipleIndexes,
    PeopleWithAssociation,
    PeopleWithAssociationMultipleIndexes,
    PeopleWithCustomObjectId,
    PeopleWithCustomObjectIdMultipleIndexes
  }

  @ref1 Ecto.UUID.generate()
  @ref2 Ecto.UUID.generate()
  @ref3 Ecto.UUID.generate()

  setup do
    Algoliax.SettingsStore.set_settings(:algoliax_people, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_people_en, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_en.tmp", %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_fr, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_fr.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_people_fail, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_fail.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_people_fail_en, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_fail_en.tmp", %{})
    Algoliax.SettingsStore.set_settings(:algoliax_people_fail_fr, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_fail_fr.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_people_without_id, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_without_id.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_with_schemas, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_with_schemas.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_people_ecto_with_association, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_ecto_with_association.tmp", %{})

    Algoliax.SettingsStore.set_settings(:algoliax_people_with_custom_object_id, %{})
    Algoliax.SettingsStore.set_settings(:"algoliax_people_with_custom_object_id.tmp", %{})

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    [
      %PeopleEcto{reference: @ref1, last_name: "Doe", first_name: "John", age: 77},
      %PeopleEcto{reference: @ref2, last_name: "al", first_name: "bert", age: 35},
      %PeopleEcto{reference: @ref3, last_name: "Vador", first_name: "Dark", age: 9}
    ]
    |> Enum.each(fn p ->
      p
      |> Ecto.Changeset.change()
      |> Algoliax.Repo.insert()
    end)

    [
      %PeopleWithoutIdEcto{
        reference: @ref1,
        last_name: "Doe",
        first_name: "John",
        age: 77,
        inserted_at: ~N[2020-03-10 17:05:20]
      },
      %PeopleWithoutIdEcto{
        reference: @ref2,
        last_name: "al",
        first_name: "bert",
        age: 35,
        inserted_at: ~N[2020-03-10 17:05:27]
      },
      %PeopleWithoutIdEcto{
        reference: @ref3,
        last_name: "Vador",
        first_name: "Dark",
        age: 9,
        inserted_at: ~N[2020-03-10 17:05:32]
      }
    ]
    |> Enum.each(fn p ->
      p
      |> Ecto.Changeset.change()
      |> Algoliax.Repo.insert()
    end)

    [
      %Beer{kind: "brune", name: "chimay", id: 1},
      %Beer{kind: "blonde", name: "jupiler", id: 2},
      %Beer{kind: "blonde", name: "heineken", id: 3}
    ]
    |> Enum.each(fn b ->
      b
      |> Ecto.Changeset.change()
      |> Algoliax.Repo.insert()
    end)

    [
      %PeopleWithAssociation{
        reference: @ref1,
        last_name: "Doe",
        first_name: "John",
        age: 77,
        animals: [%Animal{kind: "cat"}, %Animal{kind: "snake"}]
      },
      %PeopleWithAssociation{
        reference: @ref1,
        last_name: "Einstein",
        first_name: "Alber",
        age: 22,
        animals: [%Animal{kind: "cat"}, %Animal{kind: "snake"}, %Animal{kind: "dog"}]
      },
      %PeopleWithAssociation{reference: @ref2, last_name: "al", first_name: "bert", age: 35},
      %PeopleWithAssociation{
        reference: @ref3,
        last_name: "Vador",
        first_name: "Dark",
        age: 9,
        animals: [%Animal{kind: "dog"}]
      },
      %PeopleWithAssociationMultipleIndexes{
        reference: @ref1,
        last_name: "Doe",
        first_name: "John",
        age: 77,
        flowers: [%Flower{kind: "rose"}, %Flower{kind: "lily"}]
      },
      %PeopleWithAssociationMultipleIndexes{
        reference: @ref1,
        last_name: "Einstein",
        first_name: "Alber",
        age: 22,
        flowers: [%Flower{kind: "rose"}, %Flower{kind: "lily"}, %Flower{kind: "orchid"}]
      },
      %PeopleWithAssociationMultipleIndexes{
        reference: @ref2,
        last_name: "al",
        first_name: "bert",
        age: 35
      },
      %PeopleWithAssociationMultipleIndexes{
        reference: @ref3,
        last_name: "Vador",
        first_name: "Dark",
        age: 9,
        flowers: [%Flower{kind: "orchid"}]
      }
    ]
    |> Enum.each(fn p ->
      p
      |> Ecto.Changeset.change()
      |> Algoliax.Repo.insert()
    end)

    :ok
  end

  test "reindex" do
    assert {:ok, [{:ok, %Algoliax.Response{}}, {:ok, %Algoliax.Response{}}]} =
             PeopleEcto.reindex()

    assert_request("POST", %{
      "requests" => [
        %{
          "action" => "updateObject",
          "body" => %{
            "objectID" => @ref1,
            "last_name" => "Doe",
            "first_name" => "John",
            "age" => 77
          }
        }
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{
          "action" => "updateObject",
          "body" => %{
            "objectID" => @ref2,
            "last_name" => "al",
            "first_name" => "bert",
            "age" => 35
          }
        }
      ]
    })
  end

  test "reindex multiple indexes" do
    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_people_en,
                responses: [{:ok, %Algoliax.Response{}}, {:ok, %Algoliax.Response{}}]
              },
              %Algoliax.Responses{
                index_name: :algoliax_people_fr,
                responses: [{:ok, %Algoliax.Response{}}, {:ok, %Algoliax.Response{}}]
              }
            ]} = PeopleEctoMultipleIndexes.reindex()

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{
          "action" => "updateObject",
          "body" => %{
            "objectID" => @ref1,
            "last_name" => "Doe",
            "first_name" => "John",
            "age" => 77
          }
        }
      ]
    })

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{
          "action" => "updateObject",
          "body" => %{
            "objectID" => @ref2,
            "last_name" => "al",
            "first_name" => "bert",
            "age" => 35
          }
        }
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{
          "action" => "updateObject",
          "body" => %{
            "objectID" => @ref1,
            "last_name" => "Doe",
            "first_name" => "John",
            "age" => 77
          }
        }
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{
          "action" => "updateObject",
          "body" => %{
            "objectID" => @ref2,
            "last_name" => "al",
            "first_name" => "bert",
            "age" => 35
          }
        }
      ]
    })
  end

  test "reindex with force delete" do
    assert {:ok,
            [
              {:ok, %Algoliax.Response{}},
              {:ok, %Algoliax.Response{}},
              {:ok, %Algoliax.Response{}}
            ]} = PeopleEcto.reindex(force_delete: true)

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "deleteObject", "body" => %{"objectID" => @ref3}}
      ]
    })
  end

  test "reindex multiple indexes with force delete" do
    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_people_en,
                responses: [
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}}
                ]
              },
              %Algoliax.Responses{
                index_name: :algoliax_people_fr,
                responses: [
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}}
                ]
              }
            ]} = PeopleEctoMultipleIndexes.reindex(force_delete: true)

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "deleteObject", "body" => %{"objectID" => @ref3}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "deleteObject", "body" => %{"objectID" => @ref3}}
      ]
    })
  end

  test "reindex with query" do
    query =
      from(p in PeopleEcto,
        where: p.age == 35
      )

    assert {:ok, [{:ok, %Algoliax.Response{}}]} = PeopleEcto.reindex(query)

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })
  end

  test "reindex nothing as no result" do
    query =
      from(p in PeopleEcto,
        where: p.age == 999
      )

    assert {:ok, []} = PeopleEcto.reindex(query)
  end

  test "reindex multiple indexes with query" do
    query =
      from(p in PeopleEctoMultipleIndexes,
        where: p.age == 35
      )

    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_people_en,
                responses: [
                  {:ok, %Algoliax.Response{}}
                ]
              },
              %Algoliax.Responses{
                index_name: :algoliax_people_fr,
                responses: [
                  {:ok, %Algoliax.Response{}}
                ]
              }
            ]} = PeopleEctoMultipleIndexes.reindex(query)

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })
  end

  test "reindex with query and force delete" do
    query =
      from(p in PeopleEcto,
        where: p.age == 35 or p.first_name == "Dark"
      )

    assert {:ok,
            [
              {:ok, %Algoliax.Response{}},
              {:ok, %Algoliax.Response{}}
            ]} = PeopleEcto.reindex(query, force_delete: true)

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "deleteObject", "body" => %{"objectID" => @ref3}}
      ]
    })
  end

  test "reindex multiple indexes with query and force delete" do
    query =
      from(p in PeopleEctoMultipleIndexes,
        where: p.age == 35 or p.first_name == "Dark"
      )

    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_people_en,
                responses: [
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}}
                ]
              },
              %Algoliax.Responses{
                index_name: :algoliax_people_fr,
                responses: [
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}}
                ]
              }
            ]} = PeopleEctoMultipleIndexes.reindex(query, force_delete: true)

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "deleteObject", "body" => %{"objectID" => @ref3}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "deleteObject", "body" => %{"objectID" => @ref3}}
      ]
    })
  end

  test "reindex atomic" do
    assert {:ok, :completed} = PeopleEcto.reindex_atomic()

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people\.tmp/, %{
      "destination" => "algoliax_people",
      "operation" => "move"
    })
  end

  test "reindex atomic for multiple indexes" do
    assert [{:ok, :completed}, {:ok, :completed}] = PeopleEctoMultipleIndexes.reindex_atomic()

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_en\.tmp/, %{
      "destination" => "algoliax_people_en",
      "operation" => "move"
    })

    assert_request("POST", ~r/algoliax_people_fr\.tmp/, %{
      "destination" => "algoliax_people_fr",
      "operation" => "move"
    })
  end

  test "reindex atomic with fail" do
    assert_raise Postgrex.Error, fn ->
      PeopleEctoFail.reindex_atomic()
    end

    assert_request("DELETE", ~r/algoliax_people_fail\.tmp/, %{})
    refute Algoliax.SettingsStore.reindexing?(:algoliax_people_fail)
  end

  test "reindex multiple indexes atomic with fail" do
    assert_raise Postgrex.Error, fn ->
      PeopleEctoFailMultipleIndexes.reindex_atomic()
    end

    assert_request("DELETE", ~r/algoliax_people_fail_en\.tmp/, %{})
    refute Algoliax.SettingsStore.reindexing?(:algoliax_people_fail_en)
    refute Algoliax.SettingsStore.reindexing?(:algoliax_people_fail_fr)
  end

  test "reindex without an id column" do
    assert {:ok,
            [
              {:ok, %Algoliax.Response{}},
              {:ok, %Algoliax.Response{}},
              {:ok, %Algoliax.Response{}}
            ]} = PeopleWithoutIdEcto.reindex()

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref3}}
      ]
    })
  end

  test "reindex multiple indexes without an id column" do
    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_people_without_id_en,
                responses: [
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}}
                ]
              },
              %Algoliax.Responses{
                index_name: :algoliax_people_without_id_fr,
                responses: [
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}},
                  {:ok, %Algoliax.Response{}}
                ]
              }
            ]} = PeopleWithoutIdEctoMultipleIndexes.reindex()

    assert_request("POST", ~r/algoliax_people_without_id_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_without_id_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_without_id_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref3}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_without_id_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref1}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_without_id_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref2}}
      ]
    })

    assert_request("POST", ~r/algoliax_people_without_id_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"objectID" => @ref3}}
      ]
    })
  end

  test "save_object/1 without attribute(s)" do
    assert {:ok, _} = PeopleWithSchemas.save_object(%Beer{kind: "brune", name: "chimay", id: 1})

    assert_request("PUT", %{
      "name" => "chimay",
      "objectID" => 1
    })
  end

  test "save_object/1 without attribute(s) and multiple indexes" do
    assert {:ok, [%Algoliax.Responses{}, %Algoliax.Responses{}]} =
             PeopleWithSchemasMultipleIndexes.save_object(%Beer{
               kind: "brune",
               name: "chimay",
               id: 1
             })

    assert_request("PUT", ~r/algoliax_with_schemas_en/, %{
      "name" => "chimay",
      "objectID" => 1
    })

    assert_request("PUT", ~r/algoliax_with_schemas_fr/, %{
      "name" => "chimay",
      "objectID" => 1
    })
  end

  test "reindex/1 with schemas" do
    assert PeopleWithSchemas.reindex()

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "chimay", "objectID" => 1}}
      ]
    })

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "jupiler", "objectID" => 2}}
      ]
    })
  end

  test "reindex/1 with schemas and multiple indexes" do
    assert PeopleWithSchemasMultipleIndexes.reindex()

    assert_request("POST", ~r/algoliax_with_schemas_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "chimay", "objectID" => 1}}
      ]
    })

    assert_request("POST", ~r/algoliax_with_schemas_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "jupiler", "objectID" => 2}}
      ]
    })

    assert_request("POST", ~r/algoliax_with_schemas_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "chimay", "objectID" => 1}}
      ]
    })

    assert_request("POST", ~r/algoliax_with_schemas_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "jupiler", "objectID" => 2}}
      ]
    })
  end

  test "reindex/1 with schemas and query" do
    query =
      from(b in Beer,
        where: b.name == "chimay"
      )

    assert {:ok, _} = PeopleWithSchemas.reindex(query)

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "chimay", "objectID" => 1}}
      ]
    })
  end

  test "reindex/1 with schemas, query and multiple indexes" do
    query =
      from(b in Beer,
        where: b.name == "chimay"
      )

    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_with_schemas_en,
                responses: [
                  {:ok, %Algoliax.Response{}}
                ]
              },
              %Algoliax.Responses{
                index_name: :algoliax_with_schemas_fr,
                responses: [
                  {:ok, %Algoliax.Response{}}
                ]
              }
            ]} = PeopleWithSchemasMultipleIndexes.reindex(query)

    assert_request("POST", ~r/algoliax_with_schemas_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "chimay", "objectID" => 1}}
      ]
    })

    assert_request("POST", ~r/algoliax_with_schemas_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "chimay", "objectID" => 1}}
      ]
    })
  end

  test "reindex/1 with schemas and query as keyword list" do
    query = %{where: [name: "heineken"]}
    assert {:ok, _} = PeopleWithSchemas.reindex(query)

    assert_request("POST", %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "heineken", "objectID" => 3}}
      ]
    })
  end

  test "reindex/1 with schemas, query as keyword list and multiple indexes" do
    query = %{where: [name: "heineken"]}

    assert {:ok,
            [
              %Algoliax.Responses{
                index_name: :algoliax_with_schemas_en,
                responses: [
                  {:ok, %Algoliax.Response{}}
                ]
              },
              %Algoliax.Responses{
                index_name: :algoliax_with_schemas_fr,
                responses: [
                  {:ok, %Algoliax.Response{}}
                ]
              }
            ]} = PeopleWithSchemasMultipleIndexes.reindex(query)

    assert_request("POST", ~r/algoliax_with_schemas_en/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "heineken", "objectID" => 3}}
      ]
    })

    assert_request("POST", ~r/algoliax_with_schemas_fr/, %{
      "requests" => [
        %{"action" => "updateObject", "body" => %{"name" => "heineken", "objectID" => 3}}
      ]
    })
  end

  test "reindex/1 with association" do
    assert {:ok, _} = PeopleWithAssociation.reindex()
  end

  test "reindex/1 with association and multiple indexes" do
    assert {:ok, _} = PeopleWithAssociationMultipleIndexes.reindex()
  end

  describe "indexer w/ custom object id" do
    test "reindex" do
      assert {:ok,
              [
                {:ok, %Algoliax.Response{}},
                {:ok, %Algoliax.Response{}},
                {:ok, %Algoliax.Response{}}
              ]} = PeopleWithCustomObjectId.reindex()

      assert_request("POST", %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref1,
              "last_name" => "Doe"
            }
          }
        ]
      })

      assert_request("POST", %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref2,
              "last_name" => "al"
            }
          }
        ]
      })
    end

    test "reindex with multiple indexes" do
      assert {:ok,
              [
                %Algoliax.Responses{
                  index_name: :algoliax_people_with_custom_object_id_en,
                  responses: [
                    {:ok, %Algoliax.Response{}},
                    {:ok, %Algoliax.Response{}},
                    {:ok, %Algoliax.Response{}}
                  ]
                },
                %Algoliax.Responses{
                  index_name: :algoliax_people_with_custom_object_id_fr,
                  responses: [
                    {:ok, %Algoliax.Response{}},
                    {:ok, %Algoliax.Response{}},
                    {:ok, %Algoliax.Response{}}
                  ]
                }
              ]} = PeopleWithCustomObjectIdMultipleIndexes.reindex()

      assert_request("POST", ~r/algoliax_people_with_custom_object_id_en/, %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref1,
              "last_name" => "Doe"
            }
          }
        ]
      })

      assert_request("POST", ~r/algoliax_people_with_custom_object_id_fr/, %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref1,
              "last_name" => "Doe"
            }
          }
        ]
      })

      assert_request("POST", ~r/algoliax_people_with_custom_object_id_en/, %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref2,
              "last_name" => "al"
            }
          }
        ]
      })

      assert_request("POST", ~r/algoliax_people_with_custom_object_id_fr/, %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref2,
              "last_name" => "al"
            }
          }
        ]
      })

      assert_request("POST", ~r/algoliax_people_with_custom_object_id_en/, %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref3,
              "last_name" => "Vador"
            }
          }
        ]
      })

      assert_request("POST", ~r/algoliax_people_with_custom_object_id_fr/, %{
        "requests" => [
          %{
            "action" => "updateObject",
            "body" => %{
              "objectID" => "people-" <> @ref3,
              "last_name" => "Vador"
            }
          }
        ]
      })
    end
  end
end
