defmodule Algoliax.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:peoples) do
      add(:reference, :uuid)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
      add(:gender, :string)

      timestamps()
    end

    create table(:peoples_fail,  primary_key: false) do
      add(:reference, :uuid, null: false, primary_key: true)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
      add(:gender, :string)

      timestamps()
    end
  end
end
