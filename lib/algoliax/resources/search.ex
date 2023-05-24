defmodule Algoliax.Resources.Search do
  @moduledoc false
  import Algoliax.Utils, only: [index_name: 2, camelize: 1]
  import Algoliax.Client, only: [request: 1]

  def search(module, settings, query, params) do
    index_name(module, settings)
    |> Enum.map(fn index_name ->
      body =
        %{
          query: query
        }
        |> Map.merge(camelize(params))

      request(%{
        action: :search,
        url_params: [index_name: index_name],
        body: body
      })
    end)
    |> case do
      [single_result] -> single_result
      [_ | _] = multiple_result -> multiple_result
    end
  end

  def search_facet(module, settings, facet_name, facet_query, params) do
    index_name(module, settings)
    |> Enum.map(fn index_name ->
      body =
        case facet_query do
          nil ->
            %{}

          _ ->
            %{facetQuery: facet_query}
        end
        |> Map.merge(camelize(params))

      request(%{
        action: :search_facet,
        url_params: [index_name: index_name, facet_name: facet_name],
        body: body
      })
    end)
    |> case do
      [single_result] -> single_result
      [_ | _] = multiple_result -> multiple_result
    end
  end
end
