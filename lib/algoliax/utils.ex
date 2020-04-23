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
