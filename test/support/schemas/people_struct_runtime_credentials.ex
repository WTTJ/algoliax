defmodule Algoliax.Schemas.PeopleStructRuntimeCredentials do
  @moduledoc false

  use Algoliax.Indexer,
    index_name: :people_runtime_index,
    object_id: :reference,
    algolia: [
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(update_at)"]
    ],
    api_key: :api_key,
    application_id: :application_id

  defstruct reference: nil, last_name: nil, first_name: nil, age: nil

  def api_key do
    "fn_api_key"
  end

  def application_id do
    "fn_application_id"
  end
end
