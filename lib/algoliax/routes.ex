defmodule Algoliax.Routes do
  @moduledoc false
  alias Algoliax.Config

  @host_read "-dsn.algolia.net/1/indexes"
  @host_write ".algolia.net/1/indexes"
  @host_retry ".algolianet.com/1/indexes"

  @paths %{
    search: {"/{index_name}/query", :post},
    search_facet: {"/{index_name}/facets/{facet_name}/query", :post},
    delete_index: {"/{index_name}", :delete},
    move_index: {"/{index_name}/operation", :post},
    get_settings: {"/{index_name}/settings", :get},
    configure_index: {"/{index_name}/settings", :put},
    save_objects: {"/{index_name}/batch", :post},
    get_object: {"/{index_name}/{object_id}", :get},
    save_object: {"/{index_name}/{object_id}", :put},
    delete_object: {"/{index_name}/{object_id}", :delete}
  }

  def url(action, url_params, retry \\ 0) do
    {action_path, method} =
      @paths
      |> Map.get(action)

    url =
      action_path
      |> build_path(url_params)
      |> build_url(method, retry)

    {method, url}
  end

  defp build_path(path, args) do
    args
    |> Keyword.keys()
    |> Enum.reduce(path, fn key, path ->
      path
      |> String.replace("{#{key}}", "#{Keyword.get(args, key)}")
    end)
  end

  defp build_url(path, method, 0) do
    host =
      if method == :get do
        @host_read
      else
        @host_write
      end

    "https://" <> Config.application_id() <> host <> path
  end

  defp build_url(path, _method, retry) do
    "https://" <> Config.application_id() <> "-" <> "#{retry}" <> @host_retry <> path
  end
end
