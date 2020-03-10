# defmodule Algoliax.SchemaTest do
#   use Algoliax.RequestCase

#   import Ecto.Query
#   alias Algoliax.PeopleEcto
# end

defmodule AlgoliaxTest.Schema do
  use Algoliax.RequestCase
  import Ecto.Query

  alias Algoliax.Repo
  alias Algoliax.Schemas.{Animal, PeopleEcto, PeopleWithoutIdEcto, PeopleEctoWithAssociation}

  @ref1 Ecto.UUID.generate()
  @ref2 Ecto.UUID.generate()
  @ref3 Ecto.UUID.generate()

  setup do
    Algoliax.Agent.set_settings(:algoliax_people, %{})
    Algoliax.Agent.set_settings(:"algoliax_people.tmp", %{})

    Algoliax.Agent.set_settings(:algoliax_people_without_id, %{})
    Algoliax.Agent.set_settings(:"algoliax_people_without_id.tmp", %{})

    Algoliax.Agent.set_settings(:algoliax_people_ecto_with_association, %{})
    Algoliax.Agent.set_settings(:"algoliax_people_ecto_with_association.tmp", %{})

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
    assert {:ok, res} = PeopleEcto.reindex()

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
  end

  test "reindex with force delete" do
    assert {:ok, res} = PeopleEcto.reindex(force_delete: true)

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

  test "reindex with query" do
    query =
      from(p in PeopleEcto,
        where: p.age == 35
      )

    assert {:ok, res} = PeopleEcto.reindex(query)

    assert_request("POST", %{
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

    assert {:ok, res} = PeopleEcto.reindex(query, force_delete: true)

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

  test "reindex atomic" do
    assert {:ok, res} = PeopleEcto.reindex_atomic()

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

  test "reindex without an id column" do
    assert {:ok, res} = PeopleWithoutIdEcto.reindex()

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

  test "reindex with association" do
    assert {:ok, res} = PeopleEctoWithAssociation.reindex()

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
end
