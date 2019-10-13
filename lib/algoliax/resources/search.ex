defmodule Algoliax.Resources.Search do
  @moduledoc false
  alias Algoliax.{Utils, Config}

  def search_index(settings, query, params) do
    index_name = Utils.index_name(settings)

    body =
      %{
        query: query
      }
      |> Map.merge(Utils.camelize(params))

    Config.requests().search_index(index_name, body)
  end

  def search_facet(settings, facet_name, facet_query, params) do
    index_name = Utils.index_name(settings)

    body =
      case facet_query do
        nil ->
          %{}

        _ ->
          %{facetQuery: facet_query}
      end
      |> Map.merge(Utils.camelize(params))

    Config.requests().search_facet(index_name, facet_name, body)
  end
end
