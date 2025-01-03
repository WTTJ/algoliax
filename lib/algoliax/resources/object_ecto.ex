if Code.ensure_loaded?(Ecto) do
  defmodule Algoliax.Resources.ObjectEcto do
    @moduledoc false

    import Ecto.Query
    import Algoliax.Client, only: [request: 1]

    import Algoliax.Utils,
      only: [
        api_key: 2,
        application_id: 2,
        default_filters: 2,
        index_name: 2,
        schemas: 2
      ]

    alias Algoliax.Resources.Object

    def reindex(module, settings, %Ecto.Query{} = query, opts) do
      repo = Algoliax.UtilsEcto.repo(settings)

      Algoliax.UtilsEcto.find_in_batches(repo, query, 0, settings, fn batch ->
        Object.save_objects(module, settings, batch, opts)
      end)
      |> render_reindex()
    end

    def reindex(module, settings, nil, opts) do
      reindex(module, settings, %{}, opts)
    end

    def reindex(module, settings, query_filters, opts) when is_map(query_filters) do
      repo = Algoliax.UtilsEcto.repo(settings)

      # Use the default filters if none are provided
      filters =
        if map_size(query_filters) == 0 do
          default_filters(module, settings)
        else
          query_filters
        end

      module
      |> fetch_schemas(settings)
      |> Enum.reduce([], fn {schema, preloads}, acc ->
        where_filters = extract_where_filters_for_schema(filters, schema)

        query =
          from(m in schema)
          |> where(^where_filters)
          |> preload(^preloads)

        Algoliax.UtilsEcto.find_in_batches(
          repo,
          query,
          0,
          settings,
          fn batch ->
            Object.save_objects(module, settings, batch, opts)
          end,
          acc
        )
      end)
      |> render_reindex()
    end

    def reindex(_, _, _, _) do
      {:error, :invalid_query}
    end

    # Defaults to the root `:where` key if the `schema => :where` key does not exist
    defp extract_where_filters_for_schema(filters, schema) when is_map(filters) do
      root_where_filters = Map.get(filters, :where, [])
      schema_filters = Map.get(filters, schema, %{})
      Map.get(schema_filters, :where, root_where_filters)
    end

    defp fetch_schemas(module, settings) do
      schemas(module, settings)
      |> Enum.map(fn
        m when is_tuple(m) -> m
        m -> {m, []}
      end)
    end

    # sobelow_skip ["DOS.BinToAtom"]
    def reindex_atomic(module, settings) do
      api_key = api_key(module, settings)
      application_id = application_id(module, settings)

      Algoliax.UtilsEcto.repo(settings)

      index_name(module, settings)
      |> Enum.map(fn index_name ->
        tmp_index_name = :"#{index_name}.tmp"

        tmp_settings =
          settings |> Keyword.put(:index_name, tmp_index_name) |> Keyword.delete(:replicas)

        Algoliax.SettingsStore.start_reindexing(index_name)

        try do
          reindex(module, tmp_settings, nil, [])

          request(%{
            action: :move_index,
            url_params: [
              index_name: tmp_index_name,
              application_id: application_id
            ],
            body: %{
              operation: "move",
              destination: "#{index_name}"
            },
            api_key: api_key,
            application_id: application_id
          })

          {:ok, :completed}
        after
          Algoliax.Resources.Index.delete_index(module, tmp_settings)
          Algoliax.SettingsStore.delete_settings(tmp_index_name)
          Algoliax.SettingsStore.stop_reindexing(index_name)
        end
      end)
      |> render_reindex_atomic()
    end

    defp render_reindex(responses) do
      results =
        responses
        |> Enum.reject(&is_nil/1)
        |> case do
          [] ->
            []

          [{:ok, %Algoliax.Response{}} | _] = single_index_responses ->
            single_index_responses

          [{:ok, [%Algoliax.Responses{} | _]} | _] = multiple_index_responses ->
            multiple_index_responses
            |> Enum.reduce([], fn {:ok, responses}, acc -> acc ++ responses end)
            |> Enum.group_by(& &1.index_name)
            |> Enum.map(fn {index_name, list} ->
              %Algoliax.Responses{
                index_name: index_name,
                responses: Enum.flat_map(list, & &1.responses)
              }
            end)
        end

      {:ok, results}
    end

    defp render_reindex_atomic([response]), do: response
    defp render_reindex_atomic([_ | _] = responses), do: responses
  end
end
