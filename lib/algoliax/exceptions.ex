defmodule Algoliax.InvalidApiKeyParamsError do
  @moduledoc "Raise when trying to generate a secured api key with invalid params"

  defexception [:message]
end

defmodule Algoliax.MissingRepoError do
  @moduledoc "Raise when trying to use ecto specific functions without defining a repo"

  defexception [:message]

  @impl true
  def exception(index_name) do
    %__MODULE__{message: "No repo configured for index #{index_name}"}
  end
end

defmodule Algoliax.MissingIndexNameError do
  @moduledoc "Raise when trying to use algoliax without defining an index name"

  defexception [:message]

  @impl true
  def exception(_) do
    %__MODULE__{message: "No index_name configured"}
  end
end
