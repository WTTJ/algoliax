if Code.ensure_loaded?(Ecto) do
  defmodule Algoliax.UtilsEcto do
    @moduledoc false

    import Ecto.Query
    @batch_size Application.compile_env(:algoliax, :batch_size, 500)

    def repo(settings) do
      index_name = Keyword.get(settings, :index_name)
      repo = Keyword.get(settings, :repo)

      if repo do
        repo
      else
        raise Algoliax.MissingRepoError, index_name
      end
    end

    def find_in_batches(repo, query, cursor, settings, execute, acc \\ []) do
      cursor_field = Keyword.get(settings, :cursor_field, Algoliax.Config.cursor_field()) || :id
      preloads = Keyword.get(settings, :preloads, [])

      q =
        if cursor == 0 do
          from(q in query, limit: ^@batch_size, order_by: field(q, ^cursor_field))
        else
          from(q in query,
            limit: ^@batch_size,
            where: field(q, ^cursor_field) > ^cursor,
            order_by: field(q, ^cursor_field)
          )
        end

      results =
        repo.all(q)
        |> repo.preload(preloads)

      acc =
        if Enum.any?(results) do
          acc ++ [execute.(results)]
        else
          acc
        end

      if length(results) == @batch_size do
        last_cursor = results |> List.last() |> Map.get(cursor_field)
        find_in_batches(repo, query, last_cursor, settings, execute, acc)
      else
        acc
      end
    end
  end
end
