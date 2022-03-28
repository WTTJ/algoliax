defmodule Algoliax.Response do
  @moduledoc """
  Algolia API response
  """

  @type t :: %__MODULE__{
          response: map(),
          task_id: integer(),
          updated_at: binary(),
          params: keyword()
        }

  defstruct [:response, :task_id, :updated_at, :params]

  def new(response, params) do
    response = %__MODULE__{
      response: response,
      task_id: response["taskID"],
      updated_at: response["updatedAt"],
      params: params
    }

    {:ok, response}
  end
end
