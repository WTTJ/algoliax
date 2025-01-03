defmodule Algoliax.Resources.Search do
  @moduledoc false

  import Algoliax.Client, only: [request: 1]

  import Algoliax.Utils,
    only: [
      api_key: 2,
      application_id: 2,
      camelize: 1,
      index_name: 2,
      render_response: 1
    ]

  def search(module, settings, query, params) do
    api_key = api_key(module, settings)
    application_id = application_id(module, settings)

    index_name(module, settings)
    |> Enum.map(fn index_name ->
      body =
        %{
          query: query
        }
        |> Map.merge(camelize(params))

      request(%{
        action: :search,
        url_params: [
          index_name: index_name,
          application_id: application_id
        ],
        body: body,
        api_key: api_key,
        application_id: application_id
      })
    end)
    |> render_response()
  end

  def search_facet(module, settings, facet_name, facet_query, params) do
    api_key = api_key(module, settings)
    application_id = application_id(module, settings)

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
        url_params: [
          index_name: index_name,
          facet_name: facet_name,
          application_id: application_id
        ],
        body: body,
        api_key: api_key,
        application_id: application_id
      })
    end)
    |> render_response()
  end
end
