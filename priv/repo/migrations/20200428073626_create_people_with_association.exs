defmodule Algoliax.Repo.Migrations.CreatePeopleWithAssociation do
  use Ecto.Migration

  def change do
    create table(:peoples_with_associations) do
      add(:reference, :uuid)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
      add(:gender, :string)

      timestamps()
    end

    create table(:animals) do
      add(:kind, :string)
      add(:people_with_association_id, references(:peoples_with_associations))

      timestamps()
    end
  end
end
