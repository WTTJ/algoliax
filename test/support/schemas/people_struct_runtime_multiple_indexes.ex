defmodule Algoliax.Schemas.PeopleStructRuntimeMultipleIndexes do
  @moduledoc false

  use Algoliax.Indexer,
    index_name: :method_to_fetch_index_name,
    object_id: :reference,
    algolia: [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"]
    ]

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  def method_to_fetch_index_name do
    [:people_runtime_index_name_en, :people_runtime_index_name_fr]
  end
end
