defmodule Algoliax.MissingRepoError do
  @moduledoc false

  defexception [:message]

  @impl true
  def exception(%{module: module, index_name: index_name}) do
    %__MODULE__{message: "No repo configured for module #{module} and index #{index_name}"}
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
  @batch_size Application.get_env(:algoliax, :batch_size, 500)

  alias Algoliax.Config

  import Ecto.Query

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

  def secondary_indexes(settings, default \\ []) do
    Keyword.get(settings, :secondary_indexes, default)
  end

  def primary_indexes(settings, default \\ nil) do
    Keyword.get(settings, :primary_indexes, default)
  end

  def repo!(module, settings) do
    index_name = Keyword.get(settings, :index_name)
    repo = Keyword.get(settings, :repo)

    if repo do
      repo
    else
      raise(Algoliax.MissingRepoError, %{index_name: index_name, module: module})
    end
  end

  def find_in_batches(repo, query, id, settings, execute) do
    cursor_field = Keyword.get(settings, :cursor_field, Config.cursor_field()) || :id
    preloads = Keyword.get(settings, :preloads, [])

    q =
      if id > 0 do
        from(q in query,
          limit: ^@batch_size,
          where: field(q, ^cursor_field) > ^id,
          order_by: field(q, ^cursor_field)
        )
      else
        from(q in query, limit: ^@batch_size, order_by: field(q, ^cursor_field))
      end

    results = repo.all(q) |> repo.preload(preloads)

    response = execute.(results)

    if length(results) == @batch_size do
      last_id = results |> List.last() |> Map.get(:id)

      find_in_batches(repo, query, last_id, settings, execute)
    else
      response
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
