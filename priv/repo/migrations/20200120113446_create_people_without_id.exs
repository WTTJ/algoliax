defmodule Algoliax.Repo.Migrations.CreatePeopleWithAssociation do
  use Ecto.Migration

  def change do
    create table(:peoples_ecto_with_association) do
      add(:reference, :uuid)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:age, :integer)
      add(:gender, :string)

      timestamps()
    end

    create table(:animals) do
      add(:kind, :string)
      add(:people_ecto_with_association_id, references(:peoples_ecto_with_association))

      timestamps()
    end
  end
end
