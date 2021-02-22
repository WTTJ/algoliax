defmodule Algoliax do
  @moduledoc """
  Algoliax is wrapper for Algolia api

  ### Configuration

  Algoliax needs only `:api_key` and `application_id` config. These configs can either be on config files or using environment varialble `"ALGOLIA_API_KEY"` and `"ALGOLIA_APPLICATION_ID"`.

      config :algoliax,
        api_key: "",
        application_id: ""
  """

  @doc """
  Generate a secured api key with filter

  ## Examples

      Algoliax.generate_secured_api_key(%{filters: "reference:10"})
      Algoliax.generate_secured_api_key(%{filters: "reference:10 OR nickname:john"})
  """

  @algolia_params [
    :filters,
    :validUntil,
    :restrictIndices,
    :restrictSources,
    :userToken
  ]

  @spec generate_secured_api_key(api_key :: String.t(), params :: map()) ::
          {:ok, binary()} | {:error, binary()}
  def generate_secured_api_key(api_key, _) when api_key in [nil, ""] do
    {:error, "Invalid api key"}
  end

  def generate_secured_api_key(api_key, params) do
    if valid_params?(params) do
      query_string = URI.encode_query(params)

      hmac =
        :crypto.hmac(
          :sha256,
          api_key,
          query_string
        )
        |> Base.encode16(case: :lower)

      {:ok, Base.encode64(hmac <> query_string)}
    else
      {:error, "Invalid params"}
    end
  end

  @spec generate_secured_api_key!(api_key :: String.t(), params :: map()) :: binary()
  def generate_secured_api_key!(api_key, params) do
    case generate_secured_api_key(api_key, params) do
      {:ok, key} ->
        key

      {:error, message} ->
        raise Algoliax.InvalidApiKeyParamsError, message: message
    end
  end

  defp valid_params?(params) do
    params
    |> Map.keys()
    |> Enum.all?(&(&1 in @algolia_params))
  end
end
