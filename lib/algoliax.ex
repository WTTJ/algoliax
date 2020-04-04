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

      Algoliax.generate_secured_api_key("reference:10")
      Algoliax.generate_secured_api_key("reference:10 OR nickname:john")
  """
  @spec generate_secured_api_key(filters :: binary()) :: binary()
  def generate_secured_api_key(filters) do
    query_string = "filters=#{URI.encode_www_form("#{filters}")}"

    hmac =
      :crypto.hmac(
        :sha256,
        Config.api_key(),
        query_string
      )
      |> Base.encode16(case: :lower)

    Base.encode64(hmac <> query_string)
  end

  @doc false
  defmacro import_if_loaded?(module) do
    module = Macro.expand(module, __ENV__)

    if Code.ensure_loaded?(module) do
      quote do
        import unquote(module)
      end
    end
  end
end
