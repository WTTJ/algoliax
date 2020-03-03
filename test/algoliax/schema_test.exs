defmodule AlgoliaxTest.Schema do
  use ExUnit.Case, async: true
  import Mox
  import Ecto.Query

  alias Algoliax.{
    Animal,
    Repo,
    PeopleEcto,
    PeopleWithoutIdEcto,
    PeopleEctoWithAssociation,
    SettingsStore
  }

  @ref1 Ecto.UUID.generate()
  @ref2 Ecto.UUID.generate()
  @ref3 Ecto.UUID.generate()

  setup do
    SettingsStore.set_settings(:algoliax_people, %{})
    SettingsStore.set_settings(:"algoliax_people.tmp", %{})

    SettingsStore.set_settings(:algoliax_people_without_id, %{})
    SettingsStore.set_settings(:"algoliax_people_without_id.tmp", %{})

    SettingsStore.set_settings(:algoliax_people_ecto_with_association, %{})
    SettingsStore.set_settings(:"algoliax_people_ecto_with_association.tmp", %{})

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
      %PeopleWithoutIdEcto{reference: @ref1, last_name: "Doe", first_name: "John", age: 77},
      %PeopleWithoutIdEcto{reference: @ref2, last_name: "al", first_name: "bert", age: 35},
      %PeopleWithoutIdEcto{reference: @ref3, last_name: "Vador", first_name: "Dark", age: 9}
    ]
    |> Enum.each(fn p ->
      p
      |> Ecto.Changeset.change()
      |> Algoliax.Repo.insert()
    end)

    [
      %PeopleEctoWithAssociation{
        reference: @ref1,
        last_name: "Doe",
        first_name: "John",
        age: 77,
        animals: [%Animal{kind: "cat"}, %Animal{kind: "snake"}]
      },
      %PeopleEctoWithAssociation{reference: @ref2, last_name: "al", first_name: "bert", age: 35},
      %PeopleEctoWithAssociation{
        reference: @ref3,
        last_name: "Vador",
        first_name: "Dark",
        age: 9,
        animals: [%Animal{kind: "dog"}]
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
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 77,
                                        first_name: "John",
                                        full_name: "John Doe",
                                        gender: nil,
                                        id: _,
                                        last_name: "Doe",
                                        nickname: "john",
                                        objectID: @ref1,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        full_name: "bert al",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        nickname: "bert",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    PeopleEcto.reindex()
  end

  test "reindex with force delete" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 77,
                                        first_name: "John",
                                        full_name: "John Doe",
                                        gender: nil,
                                        id: _,
                                        last_name: "Doe",
                                        nickname: "john",
                                        objectID: @ref1,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        full_name: "bert al",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        nickname: "bert",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "deleteObject",
                                      body: %{
                                        age: 9,
                                        first_name: "Dark",
                                        full_name: "Dark Vador",
                                        gender: nil,
                                        id: _,
                                        last_name: "Vador",
                                        nickname: "dark",
                                        objectID: @ref3,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    PeopleEcto.reindex(force_delete: true)
  end

  test "reindex with query" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        full_name: "bert al",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        nickname: "bert",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    query =
      from(p in PeopleEcto,
        where: p.age == 35
      )

    PeopleEcto.reindex(query)
  end

  test "reindex with query and force delete" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        full_name: "bert al",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        nickname: "bert",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "deleteObject",
                                      body: %{
                                        age: 9,
                                        first_name: "Dark",
                                        full_name: "Dark Vador",
                                        gender: nil,
                                        id: _,
                                        last_name: "Vador",
                                        nickname: "dark",
                                        objectID: @ref3,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    query =
      from(p in PeopleEcto,
        where: p.age == 35 or p.first_name == "Dark"
      )

    PeopleEcto.reindex(query, force_delete: true)
  end

  test "reindex atomic" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :"algoliax_people.tmp",
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 77,
                                        first_name: "John",
                                        full_name: "John Doe",
                                        gender: nil,
                                        id: _,
                                        last_name: "Doe",
                                        nickname: "john",
                                        objectID: @ref1,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        full_name: "bert al",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        nickname: "bert",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)
    |> expect(:move_index, fn :"algoliax_people.tmp", _ ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    PeopleEcto.reindex_atomic()
  end

  test "reindex without an id column" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people_without_id,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 77,
                                        first_name: "John",
                                        gender: nil,
                                        id: _,
                                        last_name: "Doe",
                                        objectID: @ref1,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 9,
                                        first_name: "Dark",
                                        gender: nil,
                                        id: _,
                                        last_name: "Vador",
                                        objectID: @ref3,
                                        updated_at: 1_546_300_800
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    PeopleWithoutIdEcto.reindex()
  end

  test "reindex with association" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :algoliax_people_ecto_with_association,
                                %{
                                  requests: [
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 77,
                                        first_name: "John",
                                        gender: nil,
                                        id: _,
                                        last_name: "Doe",
                                        objectID: @ref1,
                                        updated_at: 1_546_300_800,
                                        animals: ["cat", "snake"]
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 35,
                                        first_name: "bert",
                                        gender: nil,
                                        id: _,
                                        last_name: "al",
                                        objectID: @ref2,
                                        updated_at: 1_546_300_800,
                                        animals: []
                                      }
                                    },
                                    %{
                                      action: "updateObject",
                                      body: %{
                                        age: 9,
                                        first_name: "Dark",
                                        gender: nil,
                                        id: _,
                                        last_name: "Vador",
                                        objectID: @ref3,
                                        updated_at: 1_546_300_800,
                                        animals: ["dog"]
                                      }
                                    }
                                  ]
                                } ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    PeopleEctoWithAssociation.reindex()
  end
end
