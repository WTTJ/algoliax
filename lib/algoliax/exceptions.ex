defmodule Algoliax.InvalidApiKeyParamsError do
  @moduledoc "Raise when trying to generate a secured api key with invalid params"

  defexception [:message]
end

defmodule Algoliax.MissingRepoError do
  @moduledoc "Raise when trying to use ecto specific functions without defining a repo"

  defexception [:message]

  @impl true
  def exception(index_name) when is_list(index_name) do
    %__MODULE__{message: "No repo configured for indexes #{Enum.join(index_name, ", ")}"}
  end

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

defmodule Algoliax.AlgoliaApiError do
  @moduledoc "Raise Algolia API error"

  defexception [:message]

  @impl true
  def exception(%{code: code, error: error}) do
    message = """
    Algolia HTTP error:

    #{code} : #{error}
    """

    %__MODULE__{message: message}
  end
end
