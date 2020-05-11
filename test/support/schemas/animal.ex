defmodule Algoliax.Schemas.Animal do
  @moduledoc false
  use Ecto.Schema

  schema "animals" do
    field(:kind)
    belongs_to(:people_with_association, Algoliax.Schemas.PeopleWithAssociation)

    timestamps()
  end
end
