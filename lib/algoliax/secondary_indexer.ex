defmodule Algoliax.SecondaryIndexer do
  @moduledoc """
  Execute save_object(s) on secondary indexes
  """

  alias Algoliax.Resources.Object

  if Mix.env() == :test do
    def run(action, module, settings, models, attributes, opts \\ []) do
      do_run(action, module, settings, models, attributes, opts)
    end
  else
    def run(action, module, settings, models, attributes, opts \\ []) do
      Task.Supervisor.start_child(Algoliax.TaskSupervisor, fn ->
        do_run(action, module, settings, models, attributes, opts)
      end)
    end
  end

  defp do_run(action, module, settings, models, attributes, opts) do
    secondary_indexes = Keyword.get(settings, :secondary_indexes, [])

    secondary_indexes
    |> Enum.each(fn secondary_index_module ->
      execute(
        action,
        module,
        apply(secondary_index_module, :algoliax_settings, []),
        models,
        attributes,
        opts
      )
    end)
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
