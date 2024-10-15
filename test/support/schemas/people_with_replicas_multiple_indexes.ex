defmodule Algoliax.Schemas.PeopleWithReplicasMultipleIndexes do
  @moduledoc false

  use Algoliax.Indexer,
    index_name: [:algoliax_people_replicas_en, :algoliax_people_replicas_fr],
    object_id: :reference,
    algolia: [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"]
    ],
    replicas: [
      [
        index_name: [:algoliax_people_replicas_asc_en, :algoliax_people_replicas_asc_fr],
        inherit: true,
        algolia: [
          searchable_attributes: ["age"],
          ranking: ["asc(age)"]
        ]
      ],
      [
        index_name: [:algoliax_people_replicas_desc_en, :algoliax_people_replicas_desc_fr],
        inherit: false,
        algolia: [ranking: ["desc(age)"]],
        if: true
      ],
      [
        index_name: [:algoliax_people_replicas_skipped_en, :algoliax_people_replicas_skipped_fr],
        inherit: true,
        algolia: [
          searchable_attributes: ["age"],
          ranking: ["asc(age)"]
        ],
        if: :do_not_deploy
      ],
      [
        index_name: [
          :algoliax_people_replicas_skipped_too_en,
          :algoliax_people_replicas_skipped_too_fr
        ],
        inherit: true,
        algolia: [
          searchable_attributes: ["age"],
          ranking: ["asc(age)"]
        ],
        if: false
      ],
      [
        index_name: [
          :algoliax_people_replicas_not_skipped_en,
          :algoliax_people_replicas_not_skipped_fr
        ],
        inherit: true,
        algolia: [
          searchable_attributes: ["age"],
          ranking: ["asc(age)"]
        ],
        if: :do_deploy
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

  def do_not_deploy, do: false
  def do_deploy, do: true
end
