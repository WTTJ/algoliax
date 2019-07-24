defmodule AlgoliaxTest.Schema do
  use ExUnit.Case, async: true
  doctest Algoliax

  defmodule Repo do
    use Ecto.Repo,
      otp_app: :algoliax,
      adapter: Ecto.Adapters.Postgres

    def init(_type, config) do
      config =
        config
        |> Keyword.put(:pool, Ecto.Adapters.SQL.Sandbox)
        |> Keyword.put(:database, "algoliax_db_test")

      {:ok, config}
    end
  end

  Repo.__adapter__().storage_down([{:database, "algoliax_db_test"}])
  Repo.__adapter__().storage_up([{:database, "algoliax_db_test"}])

  setup do
    Repo.start_link([])

    Ecto.Adapters.SQL.query!(
      Repo,
      "CREATE SEQUENCE IF NOT EXISTS  peoples_id_seq;"
    )

    Ecto.Adapters.SQL.query!(
      Repo,
      """
      CREATE TABLE IF NOT EXISTS peoples (
        id integer NOT NULL DEFAULT nextval('peoples_id_seq'),
        reference VARCHAR (50),
        last_name VARCHAR (50),
        first_name VARCHAR (50),
        age INTEGER
      );
      """
    )

    :ok
  end

  defmodule People do
    use Ecto.Schema

    use Algoliax,
      index_name: :algoliax_people,
      attribute_for_faceting: ["age"],
      custom_ranking: ["desc(update_at)"],
      repo: Repo,
      object_id: :reference

    schema "peoples" do
      field(:reference)
      field(:last_name)
      field(:first_name)
      field(:age, :integer)
    end

    # defstruct reference: nil, last_name: nil, first_name: nil, age: nil

    attributes([:first_name, :last_name, :age])

    attribute(:updated_at, DateTime.utc_now() |> DateTime.to_unix())

    attribute :full_name do
      Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
    end

    attribute :nickname do
      Map.get(model, :first_name, "") |> String.downcase()
    end
  end

  test "save_object" do
    people = [
      %People{reference: 10, last_name: "Doe", first_name: "John", age: 77},
      %People{reference: 87, last_name: "al", first_name: "bert", age: 35}
    ]
  end
end
