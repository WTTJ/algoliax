defmodule Algoliax.Repo.Migrations.CreatePeopleWithoutId do
  use Ecto.Migration

  def change do
    create table(:peoples_without_id, primary_key: false) do
      add(:reference, :uuid, primary_key: true)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
      add(:gender, :string)

      timestamps()
    end
  end
end
