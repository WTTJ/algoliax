defmodule Algoliax.Repo.Migrations.CreateBeers do
  use Ecto.Migration

  def change do
    create table(:beers) do
      add(:kind, :string)
      add(:name, :string)
      add(:abv, :float)

      timestamps()
    end
  end
end
