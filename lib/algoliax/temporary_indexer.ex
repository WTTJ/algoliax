defmodule Algoliax.TemporaryIndexer do
  @moduledoc """
  Execute save_object(s) on temporary index to keep it synchronized with main index
  """

  alias Algoliax.Resources.Object
  alias Algoliax.Utils

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
    index_name = Utils.index_name(module, settings)

    if Algoliax.Agent.reindexing?(index_name) do
      tmp_index_name = :"#{index_name}.tmp"
      tmp_settings = Algoliax.Agent.get_settings(tmp_index_name)

      execute(action, module, tmp_settings, models, attributes, opts)
    end
  end

  defp execute(:save_objects, module, settings, models, attributes, opts) do
    Object.save_objects(module, settings, models, attributes, opts)
  end

  defp execute(:save_object, module, settings, models, attributes, _) do
    Object.save_object(module, settings, models, attributes)
  end

  defp execute(:delete_object, module, settings, models, attributes, _) do
    Object.delete_object(module, settings, models, attributes)
  end
end
