defmodule Algoliax.Routes do
  @moduledoc false
  alias Algoliax.Config

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

  defp build_url(path, :get, 0) do
    url_read()
    |> String.replace(~r/{{application_id}}/, Config.application_id())
    |> Kernel.<>(path)
  end

  defp build_url(path, _method, 0) do
    url_write()
    |> String.replace(~r/{{application_id}}/, Config.application_id())
    |> Kernel.<>(path)
  end

  defp build_url(path, _method, retry) do
    url_retry()
    |> String.replace(~r/{{application_id}}/, Config.application_id())
    |> String.replace(~r/{{retry}}/, to_string(retry))
    |> Kernel.<>(path)
  end

  if Mix.env() == :test do
    defp url_read do
      port = System.get_env("SLACK_MOCK_API_PORT", "8002")
      "http://localhost:#{port}/{{application_id}}/read"
    end

    defp url_write do
      port = System.get_env("SLACK_MOCK_API_PORT", "8002")
      "http://localhost:#{port}/{{application_id}}/write"
    end

    defp url_retry do
      port = System.get_env("SLACK_MOCK_API_PORT", "8002")
      "http://localhost:#{port}/{{application_id}}/retry/{{retry}}"
    end
  else
    defp url_read do
      "https://{{application_id}}-dsn.algolia.net/1/indexes"
    end

    defp url_write do
      "https://{{application_id}}.algolia.net/1/indexes"
    end

    defp url_retry do
      "https://{{application_id}}-{{retry}}.algolianet.com/1/indexes"
    end
  end
end
