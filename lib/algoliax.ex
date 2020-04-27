defmodule Algoliax do
  @moduledoc """
  Algoliax is wrapper for Algolia api

  ### Configuration

  Algoliax needs only `:api_key` and `application_id` config. These configs can either be on config files or using environment varialble `"ALGOLIA_API_KEY"` and `"ALGOLIA_APPLICATION_ID"`.

      config :algoliax,
        api_key: "",
        application_id: ""
  """
  alias Algoliax.Config

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

  @spec generate_secured_api_key(params :: map()) ::
          {:ok, binary()} | {:error, :invalid_params}
  def generate_secured_api_key(params) do
    if valid_params?(params) do
      query_string = URI.encode_query(params)

      hmac =
        :crypto.hmac(
          :sha256,
          Config.api_key(),
          query_string
        )
        |> Base.encode16(case: :lower)

      {:ok, Base.encode64(hmac <> query_string)}
    else
      {:error, :invalid_params}
    end
  end

  @spec generate_secured_api_key!(params :: map()) :: binary()
  def generate_secured_api_key!(params) do
    case generate_secured_api_key(params) do
      {:ok, key} ->
        key

      {:error, _} ->
        raise Algoliax.InvalidApiKeyParamsError, message: "Invalid params"
    end
  end

  defp valid_params?(params) do
    params
    |> Map.keys()
    |> Enum.all?(&(&1 in @algolia_params))
  end
end
