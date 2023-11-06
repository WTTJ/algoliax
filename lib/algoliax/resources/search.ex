defmodule Algoliax.Resources.Search do
  @moduledoc false
  import Algoliax.Utils, only: [index_name: 2, camelize: 1, render_response: 1]
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
    |> render_response()
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
    |> render_response()
  end
end
