defmodule Algoliax.Resources.Task do
  @moduledoc false

  import Algoliax.Client, only: [request: 1]

  def task(%Algoliax.Response{} = response) do
    index_name = Keyword.get(response.params, :index_name)

    request(%{
      action: :task,
      url_params: [
        index_name: index_name,
        task_id: response.task_id
      ]
    })
  end
end
