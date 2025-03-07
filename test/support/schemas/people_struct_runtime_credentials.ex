defmodule Algoliax.Schemas.PeopleStructCredentials do
  @moduledoc false

  use Algoliax.Indexer,
    index_name: :people_runtime_index,
    object_id: :reference,
    algolia: [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"]
    ],
    credentials: :custom_1

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil
end
