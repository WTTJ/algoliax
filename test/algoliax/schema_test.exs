defmodule AlgoliaxTest.Schema do
  use ExUnit.Case, async: true
  import Mox

  alias Algoliax.{Repo, PeopleEcto}

  @ref1 Ecto.UUID.generate()
  @ref2 Ecto.UUID.generate()

  setup do
    Algoliax.Agent.set_settings(:algoliax_people, %{})
    Algoliax.Agent.set_settings(:"algoliax_people.tmp", %{})

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    [
      %PeopleEcto{reference: @ref1, last_name: "Doe", first_name: "John", age: 77},
      %PeopleEcto{reference: @ref2, last_name: "al", first_name: "bert", age: 35}
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
    |> expect(:save_objects, fn :algoliax_people, _ ->
      %{
        "taskID" => 792,
        "objectIDs" => [@ref2, @ref1]
      }
    end)

    PeopleEcto.reindex()
  end

  test "reindex atomic" do
    Algoliax.RequestsMock
    |> expect(:save_objects, fn :"algoliax_people.tmp", _ ->
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
end
