defmodule Algoliax.Client do
  @moduledoc false

  require Logger

  alias Algoliax.{Config, Routes}
  @recv_timeout Application.compile_env(:algoliax, :recv_timeout, 5000)

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
        build_response(response, request)

      {:ok, code, _, response} when code in 300..499 ->
        handle_error(code, response, action)

      error ->
        Logger.debug("#{inspect(error)}")
        request(request, retry + 1)
    end
  end

  defp handle_error(404, response, action) when action in [:get_settings, :get_object] do
    {:error, 404, response}
  end

  defp handle_error(code, response, _action) do
    error =
      case Jason.decode(response) do
        {:ok, response} -> Map.get(response, "message")
        _ -> response
      end

    raise Algoliax.AlgoliaApiError, %{code: code, error: error}
  end

  defp build_response(response, request) do
    case Jason.decode(response) do
      {:ok, response} -> Algoliax.Response.new(response, request[:url_params])
      error -> error
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
