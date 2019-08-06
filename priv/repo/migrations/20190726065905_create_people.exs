defmodule Algoliax.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:peoples) do
      add(:reference, :integer)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
    end
  end
end
