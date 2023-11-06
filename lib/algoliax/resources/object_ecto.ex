if Code.ensure_loaded?(Ecto) do
  defmodule Algoliax.Resources.ObjectEcto do
    @moduledoc false

    import Ecto.Query
    import Algoliax.Client, only: [request: 1]
    import Algoliax.Utils, only: [index_name: 2, schemas: 2]

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

      module
      |> fetch_schemas(settings)
      |> Enum.reduce([], fn {mod, preloads}, acc ->
        where_filters = Map.get(query_filters, :where, [])

        query =
          from(m in mod)
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

    defp fetch_schemas(module, settings) do
      schemas(module, settings)
      |> Enum.map(fn
        m when is_tuple(m) -> m
        m -> {m, []}
      end)
    end

    # sobelow_skip ["DOS.BinToAtom"]
    def reindex_atomic(module, settings) do
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
            url_params: [index_name: tmp_index_name],
            body: %{
              operation: "move",
              destination: "#{index_name}"
            }
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
