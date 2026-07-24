defmodule Algoliax.Client do
  @moduledoc false

  require Logger

  alias Algoliax.{Config, Routes}

  def request(request, retry \\ 0)

  def request(_request, 4) do
    {:error, "Failed after 3 attempts"}
  end

  def request(%{action: action, url_params: url_params} = request, retry) do
    body = Map.get(request, :body)
    query_params = Map.get(request, :query_params)
    {method, url} = Routes.url(action, url_params, query_params, retry)
    log(action, method, url, body)

    [
      method: method,
      url: url,
      headers: request_headers(),
      body: encode_body(body),
      receive_timeout: recv_timeout()
    ]
    |> Algoliax.HttpClient.impl().request()
    |> handle_result(action, request, retry)
  end

  defp handle_result({:ok, code, _headers, response}, _action, request, _retry)
       when code in 200..299 and is_binary(response) do
    build_response(response, request)
  end

  defp handle_result({:ok, code, _headers, response}, action, request, _retry)
       when code in 300..499 and is_binary(response) do
    handle_error(code, response, action, request)
  end

  # Right tuple shape and integer status, but a non-binary body violates the
  # contract (e.g. a decoded map from forgetting `decode_body: false`). Raise
  # rather than letting it fall into the retry clause below and be masked.
  defp handle_result({:ok, code, _headers, response} = result, _action, _request, _retry)
       when is_integer(code) and not is_binary(response) do
    raise Algoliax.HttpClientContractError, result
  end

  # Completed exchange with any other status (e.g. 5xx): retry against the next
  # Algolia host — unchanged from the previous hackney-based behaviour.
  defp handle_result({:ok, code, _, _} = result, _action, request, retry)
       when is_integer(code) do
    retry_after_error(request, retry, result)
  end

  # Transport-level failure: retry against the next Algolia host.
  defp handle_result({:error, _reason} = error, _action, request, retry) do
    retry_after_error(request, retry, error)
  end

  # Anything else violates the Algoliax.HttpClient contract. Fail loudly instead
  # of masking a mis-implemented client as a transport failure.
  defp handle_result(other, _action, _request, _retry) do
    raise Algoliax.HttpClientContractError, other
  end

  defp retry_after_error(request, retry, logged) do
    Logger.debug("#{inspect(logged)}")
    request(request, retry + 1)
  end

  defp handle_error(404, response, action, request) when action in [:get_settings, :get_object] do
    {:error, 404, response, request}
  end

  defp handle_error(code, response, _action, _request) do
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
    ] ++ x_forwarded_for()
  end

  defp x_forwarded_for do
    if remote_ip = Process.get(:algoliax_user_ip, nil) do
      [{"X-Forwarded-For", remote_ip}]
    else
      []
    end
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

  # Bodyless requests (get_object, get_settings, task, ...) never set :body, so
  # pass `nil` straight through rather than encoding it to the "null" binary —
  # this keeps the `Algoliax.HttpClient` `body: binary() | nil` contract honest
  # and lets implementations special-case bodyless requests with `opts[:body]`.
  defp encode_body(nil), do: nil
  defp encode_body(body), do: Jason.encode!(body)

  defp recv_timeout() do
    Application.get_env(:algoliax, :recv_timeout, 5000)
  end
end
