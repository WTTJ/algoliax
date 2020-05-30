defmodule Algoliax.Client do
  @moduledoc false

  require Logger

  alias Algoliax.{Config, Routes}
  @recv_timeout Application.get_env(:algoliax, :recv_timeout, 5000)

  def request(request, retry \\ 0)

  def request(_request, 4) do
    {:error, "Failed after 3 attempts"}
  end

  def request(%{action: action, url_params: url_params} = request, retry) do
    body = Map.get(request, :body)
    {method, url} = Routes.url(action, url_params, retry)
    log(action, method, url, body)

    method
    |> :hackney.request(url, request_headers(), Jason.encode!(body), [
      :with_body,
      recv_timeout: @recv_timeout
    ])
    |> case do
      {:ok, code, _headers, response} when code in 200..299 ->
        Jason.decode(response)

      {:ok, code, _, response} when code in 300..499 ->
        {:error, code, response}

      error ->
        Logger.debug("#{inspect(error)}")
        request(request, retry + 1)
    end
  end

  defp request_headers do
    [
      {"Content-type", "application/json"},
      {"X-Algolia-API-Key", Config.api_key()},
      {"X-Algolia-Application-Id", Config.application_id()}
    ]
  end

  defp log(action, method, url, body) do
    action = action |> to_string() |> String.upcase()
    method = method |> to_string() |> String.upcase()
    message = "#{action}: #{method} #{url}"

    message =
      if body do
        message <> ", body: #{inspect(body)}"
      else
        message
      end

    Logger.debug(message)
  end
end
