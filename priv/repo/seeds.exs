Enum.each(1..1000, fn _i ->
  %Algoliax.PeopleEcto{
    reference: Faker.UUID.v4(),
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    age: :rand.uniform(90),
    gender: Enum.random(["male", "female"])
  }
  |> Ecto.Changeset.change()
  |> Algoliax.Repo.insert()
end)
