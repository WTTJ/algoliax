defmodule AlgoliaxTest.Schema do
  use ExUnit.Case, async: true
  import Mox

  alias Algoliax.{Repo, PeopleEcto}

  setup do
    Algoliax.Agent.set_settings(:algoliax_people, %{})
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    [
      %PeopleEcto{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %PeopleEcto{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]
    |> Enum.each(fn p ->
      p
      |> Ecto.Changeset.change()
      |> Algoliax.Repo.insert()
    end)

    :ok
  end

  test "save_object" do
    Algoliax.Client.HttpMock
    |> expect(:save_objects, fn :algoliax_people, _ ->
      %{
        "taskID" => 792,
        "objectIDs" => ["87", "10"]
      }
    end)

    PeopleEcto.reindex()
  end
end
