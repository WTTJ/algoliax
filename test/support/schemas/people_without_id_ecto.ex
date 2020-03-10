defmodule Algoliax.Schemas.PeopleWithoutIdEcto do
  @moduledoc false

  use Ecto.Schema

  use Algoliax,
    index_name: :algoliax_people_without_id,
    attributes_for_faceting: ["age", "gender"],
    searchable_attributes: ["firstname", "lastname"],
    custom_ranking: ["desc(updated_at)"],
    repo: Algoliax.Repo,
    object_id: :reference,
    cursor_field: :inserted_at

  @primary_key {:reference, Ecto.UUID, autogenerate: true}
  schema "peoples_without_id" do
    field(:last_name)
    field(:first_name)
    field(:age, :integer)
    field(:gender, :string)

    timestamps()
  end

  attributes([:id, :first_name, :last_name, :age, :gender])

  attribute(:updated_at, ~U[2019-01-01 00:00:00Z] |> DateTime.to_unix())
end
