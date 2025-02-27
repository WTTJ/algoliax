defmodule Algoliax.Resources.Task do
  @moduledoc false

  import Algoliax.Client, only: [request: 1]

  def task(%Algoliax.Response{} = response) do
    index_name = Keyword.get(response.params, :index_name)

    request(%{
      action: :task,
      url_params: [
        index_name: index_name,
        task_id: response.task_id,
        application_id: response.application_id
      ],
      api_key: response.api_key,
      application_id: response.application_id
    })
  end
end
