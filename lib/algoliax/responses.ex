defmodule Algoliax.Responses do
  @moduledoc """
  Algolia API responses
  """

  @type t :: %__MODULE__{
          index_name: String.t(),
          responses: list(Algoliax.Response)
        }

  defstruct [:index_name, :responses]
end
