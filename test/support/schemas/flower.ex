defmodule Algoliax.Schemas.Flower do
  @moduledoc false
  use Ecto.Schema

  schema "flowers" do
    field(:kind)

    belongs_to(
      :people_with_association_multiple_indexes,
      Algoliax.Schemas.PeopleWithAssociationMultipleIndexes
    )

    timestamps()
  end
end
