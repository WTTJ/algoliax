defmodule Algoliax.Schemas.BeerWithSchemaFilters do
  @moduledoc false

  alias Algoliax.Schemas.Beer

  use Algoliax.Indexer,
    index_name: :algoliax_beer_with_schema_filters,
    repo: Algoliax.Repo,
    schemas: [Beer],
    algolia: [
      attributes_for_faceting: ["kind", "name"],
      searchable_attributes: ["kind", "name"],
      custom_ranking: ["desc(updated_at)"]
    ],
    default_filters: :get_filters

  def get_filters do
    %{Beer => %{where: [kind: "brune"]}}
  end

  def build_object(beer) do
    %{
      kind: beer.kind,
      name: beer.name,
      updated_at: ~U[2019-01-01 00:00:00Z] |> DateTime.to_unix()
    }
  end

  def to_be_indexed?(_beer), do: true
end
