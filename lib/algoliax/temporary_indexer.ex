defmodule Algoliax.TemporaryIndexer do
  @moduledoc """
  Execute save_object(s) on temporary index to keep it synchronized with main index
  """

  import Algoliax.Utils, only: [index_name: 2, render_response: 1, call_store: 3]

  alias Algoliax.Resources.Object

  def run(action, module, settings, models, opts \\ []) do
    do_run(action, module, settings, models, opts)
  end

  # sobelow_skip ["DOS.BinToAtom"]
  defp do_run(action, module, settings, models, opts) do
    opts = Keyword.delete(opts, :temporary_only)

    index_name(module, settings)
    |> Enum.map(fn index_name ->
      if call_store(settings, :reindexing?, [index_name]) do
        tmp_index_name = :"#{index_name}.tmp"
        tmp_settings = call_store(settings, :get_settings, [tmp_index_name])

        execute(action, module, tmp_settings, models, opts)
      end
    end)
    |> render_response()
  end

  defp execute(:save_objects, module, settings, models, opts) do
    Object.save_objects(module, settings, models, opts)
  end

  defp execute(:save_object, module, settings, models, _) do
    Object.save_object(module, settings, models)
  end

  defp execute(:delete_object, module, settings, models, _) do
    Object.delete_object(module, settings, models)
  end

  defp execute(:delete_by, module, settings, matching_filter, _) do
    Object.delete_by(module, settings, matching_filter)
  end
end
