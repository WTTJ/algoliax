defmodule Algoliax.Schemas.Animal do
  @moduledoc false

  use Ecto.Schema

  schema "animals" do
    field(:kind)
    belongs_to(:people_ecto_with_association, Algoliax.Schemas.PeopleEctoWithAssociation)

    timestamps()
  end
end
