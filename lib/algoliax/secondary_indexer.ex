defmodule Algoliax.SecondaryIndexer do
  @moduledoc """
  Execute save_object(s) on secondary indexes
  """

  import Algoliax.Utils, only: [secondary_indexes: 1, index_name: 2]
  alias Algoliax.SettingsStore
  alias Algoliax.Resources.Object

  def run(action, module, settings, models, attributes, opts \\ []) do
    do_run(action, module, settings, models, attributes, opts)
  end

  defp do_run(action, module, settings, models, attributes, opts) do
    opts = Keyword.delete(opts, :secondary_indexes_only)
    secondary_indexes = secondary_indexes(settings)

    secondary_indexes
    |> Enum.each(fn secondary_index_module ->
      execute(
        action,
        module,
        secondary_index_settings(secondary_index_module),
        models,
        attributes,
        opts
      )
    end)
  end

  defp secondary_index_settings(module) do
    settings = apply(module, :algoliax_settings, [])
    index_name = index_name(module, settings)

    if SettingsStore.reindexing?(index_name) do
      index_name = :"#{index_name}.tmp"
      settings |> Keyword.put(:index_name, index_name)
    else
      settings
    end
  end

  defp execute(:save_objects, module, settings, models, attributes, opts)
       when is_list(models) do
    Object.save_objects(module, settings, models, attributes, opts)
  end

  defp execute(:save_object, module, settings, models, attributes, _) do
    Object.save_object(module, settings, models, attributes)
  end

  defp execute(:delete_object, module, settings, models, attributes, _) do
    Object.delete_object(module, settings, models, attributes)
  end
end
