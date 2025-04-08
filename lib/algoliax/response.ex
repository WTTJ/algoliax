defmodule Algoliax.Response do
  @moduledoc """
  Algolia API response
  """

  @type t :: %__MODULE__{
          api_key: binary(),
          application_id: binary(),
          params: keyword(),
          response: map(),
          task_id: integer() | nil,
          updated_at: binary() | nil
        }

  defstruct [
    :api_key,
    :application_id,
    :params,
    :response,
    :task_id,
    :updated_at
  ]

  def new(response, request) do
    response = %__MODULE__{
      api_key: request.api_key,
      application_id: request.application_id,
      params: request.url_params,
      response: response,
      task_id: response["taskID"],
      updated_at: response["updatedAt"]
    }

    {:ok, response}
  end
end
