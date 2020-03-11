defmodule Algoliax.Schemas.Beer do
  @moduledoc false

  use Ecto.Schema

  schema "beers" do
    field(:kind)
    field(:name)
    field(:abv, :float)

    timestamps()
  end
end
