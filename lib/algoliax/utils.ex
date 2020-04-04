defmodule Algoliax.MissingRepoError do
  @moduledoc false

  defexception [:message]

  @impl true
  def exception(index_name) do
    %__MODULE__{message: "No repo configured for index #{index_name}"}
  end
end

defmodule Algoliax.MissingIndexNameError do
  @moduledoc false

  defexception [:message]

  @impl true
  def exception(_) do
    %__MODULE__{message: "No index_name configured"}
  end
end

defmodule Algoliax.Utils do
  @moduledoc false

  @attribute_prefix "algoliax_attr_"

  import Algoliax, only: [import_if_loaded?: 1]
  import_if_loaded?(Ecto.Query)

  def prefix_attribute(attribute) do
    :"#{@attribute_prefix}#{attribute}"
  end

  def unprefix_attribute(attribute) do
    attribute
    |> Atom.to_string()
    |> String.replace(@attribute_prefix, "")
    |> String.to_atom()
  end

  def index_name(module, settings) do
    index_name = Keyword.get(settings, :index_name)

    if index_name do
      if module.__info__(:functions)
         |> Keyword.get(index_name) == 0 do
        apply(module, index_name, [])
      else
        index_name
      end
    else
      raise Algoliax.MissingIndexNameError
    end
  end

  def algolia_settings(settings) do
    Keyword.get(settings, :algolia, [])
  end

  def object_id_attribute(settings) do
    Keyword.get(settings, :object_id, :id)
  end

  def schemas(settings) do
    Keyword.get(settings, :schemas, [])
  end

  if Code.ensure_loaded?(Ecto) do
    @batch_size Application.get_env(:algoliax, :batch_size, 500)

    def repo(settings) do
      index_name = Keyword.get(settings, :index_name)
      repo = Keyword.get(settings, :repo)

      if repo do
        repo
      else
        raise Algoliax.MissingRepoError, index_name
      end
    end

    def find_in_batches(repo, query, cursor, settings, execute) do
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

      if Enum.any?(results) do
        execute.(results)
      end

      if length(results) == @batch_size do
        last_cursor = results |> List.last() |> Map.get(cursor_field)
        find_in_batches(repo, query, last_cursor, settings, execute)
      else
        {:ok, :completed}
      end
    end
  end

  def camelize(params) when is_map(params) do
    Enum.into(params, %{}, fn {k, v} ->
      {camelize(k), v}
    end)
  end

  def camelize(key) do
    key
    |> Atom.to_string()
    |> Inflex.camelize(:lower)
  end
end
