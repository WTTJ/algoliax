defmodule Algoliax.Routes do
  @moduledoc false

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
    delete_object: {"/{index_name}/{object_id}", :delete},
    task: {"/{index_name}/task/{task_id}", :get},
    delete_by: {"/{index_name}/deleteByQuery", :post}
  }

  def url(action, url_params, retry \\ 0) do
    {action_path, method} =
      @paths
      |> Map.get(action)

    url =
      method
      |> build_url(retry)
      |> Kernel.<>(action_path)
      |> interpolate_path(url_params)

    {method, url}
  end

  defp interpolate_path(path, args) do
    args
    |> Keyword.keys()
    |> Enum.reduce(path, fn key, path ->
      path
      |> String.replace("{#{key}}", "#{Keyword.get(args, key)}")
    end)
  end

  defp build_url(:get, 0) do
    url_read()
  end

  defp build_url(_method, 0) do
    url_write()
  end

  defp build_url(_method, retry) do
    url_retry()
    |> String.replace(~r/{{retry}}/, to_string(retry))
  end

  if Mix.env() == :test do
    defp url_read do
      port = Application.get_env(:algoliax, :mock_api_port)
      "http://localhost:#{port}/{application_id}/read"
    end

    defp url_write do
      port = Application.get_env(:algoliax, :mock_api_port)
      "http://localhost:#{port}/{application_id}/write"
    end

    defp url_retry do
      port = Application.get_env(:algoliax, :mock_api_port)
      "http://localhost:#{port}/{application_id}/retry/{{retry}}"
    end
  else
    defp url_read do
      "https://{application_id}-dsn.algolia.net/1/indexes"
    end

    defp url_write do
      "https://{application_id}.algolia.net/1/indexes"
    end

    defp url_retry do
      "https://{application_id}-{{retry}}.algolianet.com/1/indexes"
    end
  end
end
