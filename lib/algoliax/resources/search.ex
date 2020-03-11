defmodule Algoliax.Resources.Search do
  @moduledoc false
  import Algoliax.Utils, only: [index_name: 2, camelize: 1]

  alias Algoliax.Requests

  def search(module, settings, query, params) do
    index_name = index_name(module, settings)

    body =
      %{
        query: query
      }
      |> Map.merge(camelize(params))

    Requests.search(index_name, body)
  end

  def search_facet(module, settings, facet_name, facet_query, params) do
    index_name = index_name(module, settings)

    body =
      case facet_query do
        nil ->
          %{}

        _ ->
          %{facetQuery: facet_query}
      end
      |> Map.merge(camelize(params))

    Requests.search_facet(index_name, facet_name, body)
  end
end
