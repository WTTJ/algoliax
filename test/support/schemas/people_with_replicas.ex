defmodule Algoliax.Schemas.PeopleWithReplicas do
  @moduledoc false

  use Algoliax.Indexer,
    index_name: :algoliax_people_replicas,
    object_id: :reference,
    algolia: :runtime_algolia_settings,
    replicas: [
      [
        index_name: :algoliax_people_replicas_asc,
        inherit: true,
        algolia: :runtime_replica_algolia_settings
      ],
      [
        index_name: :algoliax_people_replicas_desc,
        inherit: false,
        algolia: [ranking: ["desc(age)"]]
      ]
    ]

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  def build_object(people) do
    %{
      first_name: people.first_name,
      last_name: people.last_name,
      age: people.age,
      updated_at: ~U[2019-01-01 00:00:00Z] |> DateTime.to_unix(),
      full_name: Map.get(people, :first_name, "") <> " " <> Map.get(people, :last_name, ""),
      nickname: Map.get(people, :first_name, "") |> String.downcase()
    }
  end

  def runtime_algolia_settings do
    [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"]
    ]
  end

  def runtime_replica_algolia_settings do
    [
      searchable_attributes: ["age"],
      ranking: ["asc(age)"]
    ]
  end
end
