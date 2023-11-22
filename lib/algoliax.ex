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
  Forward user ip to algolia operations

      Algoliax.with_user_ip("192.168.0.1", fn ->
        MyIndexer.search("test")
      end)

  """
  def with_user_ip(ip \\ nil, fun) do
    Process.put(:algoliax_user_ip, ip)

    try do
      fun.()
    after
      Process.delete(:algoliax_user_ip)
    end
  end

  @doc """
  Generate a secured api key with filter

  ## Examples

      Algoliax.generate_secured_api_key("api_key", %{filters: "reference:10"})
      Algoliax.generate_secured_api_key("api_key", %{filters: "reference:10 OR nickname:john"})
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
        :crypto.mac(
          :hmac,
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

  @doc """
  Same as `generate_secured_api_key/2` but returns the key or raises if invalid params

  ## Examples

      Algoliax.generate_secured_api_key!("api_key", %{filters: "reference:10"})
      Algoliax.generate_secured_api_key!("api_key", %{filters: "reference:10 OR nickname:john"})
  """
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

  @doc """
  Wait for a task to be published on Algolia side. Work with all indexer function except `reindex_atomic/0`

  ## Examples

      MyApp.People.save_object(%MyApp.People{id: 1}) |> Algoliax.wait_task()
  """
  def wait_task({:ok, response}), do: wait_task(response)

  def wait_task(tasks) when is_list(tasks) do
    tasks
    |> Enum.map(&Task.async(fn -> wait_task(&1) end))
    |> Enum.map(&Task.await/1)
  end

  def wait_task({:ok, %Algoliax.Response{task_id: nil}} = response), do: response
  def wait_task({:error} = response), do: response
  def wait_task(response), do: do_wait_task(response)

  @doc false
  def do_wait_task(response, retry \\ 0) do
    retry = retry + 1

    case Algoliax.Resources.Task.task(response) do
      {:ok, %Algoliax.Response{response: %{"status" => "published"}}} ->
        {:ok, response}

      _ ->
        :timer.sleep(min(100 * retry, 1000))
        do_wait_task(response, retry)
    end
  end
end
