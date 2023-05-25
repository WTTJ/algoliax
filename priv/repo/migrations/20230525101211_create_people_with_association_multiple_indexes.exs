defmodule Algoliax.Repo.Migrations.CreatePeopleWithAssociationMultipleIndexes do
  use Ecto.Migration

  def change do
    create table(:peoples_with_associations_multiple_indexes) do
      add(:reference, :uuid)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
      add(:gender, :string)

      timestamps()
    end

    create table(:flowers) do
      add(:kind, :string)
      add(:people_with_association_multiple_indexes_id, references(:peoples_with_associations_multiple_indexes))

      timestamps()
    end
  end
end
