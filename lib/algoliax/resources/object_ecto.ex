if Code.ensure_loaded?(Ecto) do
  defmodule Algoliax.Resources.ObjectEcto do
    @moduledoc false

    import Ecto.Query
    import Algoliax.Client, only: [request: 1]

    alias Algoliax.Resources.Object

    def reindex(module, settings, %Ecto.Query{} = query, opts) do
      repo = Algoliax.UtilsEcto.repo(settings)

      Algoliax.UtilsEcto.find_in_batches(repo, query, 0, settings, fn batch ->
        Object.save_objects(module, settings, batch, opts)
      end)
    end

    def reindex(module, settings, nil, opts) do
      reindex(module, settings, %{}, opts)
    end

    def reindex(module, settings, query_filters, opts) when is_map(query_filters) do
      repo = Algoliax.UtilsEcto.repo(settings)

      module
      |> fetch_schemas(settings)
      |> Enum.each(fn {mod, preloads} ->
        where_filters = Map.get(query_filters, :where, [])

        query =
          from(m in mod)
          |> where(^where_filters)
          |> preload(^preloads)

        Algoliax.UtilsEcto.find_in_batches(repo, query, 0, settings, fn batch ->
          Object.save_objects(module, settings, batch, opts)
        end)
      end)

      {:ok, :completed}
    end

    def reindex(_, _, _, _) do
      {:error, :invalid_query}
    end

    defp fetch_schemas(module, settings) do
      Algoliax.Utils.schemas(settings, [module])
      |> Enum.map(fn
        m when is_tuple(m) ->
          m

        m ->
          {m, []}
      end)
    end

    def reindex_atomic(module, settings) do
      Algoliax.UtilsEcto.repo(settings)
      index_name = Algoliax.Utils.index_name(module, settings)
      tmp_index_name = :"#{index_name}.tmp"
      tmp_settings = Keyword.put(settings, :index_name, tmp_index_name)

      Algoliax.SettingsStore.start_reindexing(index_name)

      reindex(module, tmp_settings, nil, [])

      request(%{
        action: :move_index,
        url_params: [index_name: tmp_index_name],
        body: %{
          operation: "move",
          destination: "#{index_name}"
        }
      })

      Algoliax.SettingsStore.delete_settings(tmp_index_name)
      Algoliax.SettingsStore.stop_reindexing(index_name)

      {:ok, :completed}
    end
  end
end
