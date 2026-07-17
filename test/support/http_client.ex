defmodule Algoliax.Support.HttpClient do
  @moduledoc """
  `Algoliax.HttpClient` implementation backed by `Req`.

  Algoliax itself ships no HTTP client; this adapter lets the test suite reach
  the local `Algoliax.ApiMockServer`, and doubles as the reference
  implementation linked from the README.
  """

  @behaviour Algoliax.HttpClient

  @impl Algoliax.HttpClient
  def request(opts) do
    opts
    |> build_req_opts()
    |> Req.request()
    |> to_result()
  end

  defp build_req_opts(opts) do
    opts
    |> Keyword.take([:method, :url, :headers, :body, :receive_timeout])
    |> Keyword.put(:decode_body, false)
    |> Keyword.put(:retry, false)
    |> Keyword.put(:redirect, false)
  end

  @doc """
  Maps a `Req.request/1` result onto the `Algoliax.HttpClient` contract.

  Split out from `request/1` so the error branches are testable without
  provoking a live Req failure. The `Req.TransportError` clause unwraps to the
  bare reason; the final clause is a defensive passthrough for any other error
  struct Req may return.
  """
  @spec to_result(term()) :: Algoliax.HttpClient.result()
  def to_result({:ok, %Req.Response{status: status, headers: headers, body: body}}) do
    {:ok, status, normalize_headers(headers), body}
  end

  def to_result({:error, %Req.TransportError{reason: reason}}), do: {:error, reason}
  def to_result({:error, reason}), do: {:error, reason}

  defp normalize_headers(headers) do
    Enum.flat_map(headers, fn {k, vs} -> Enum.map(vs, &{k, &1}) end)
  end
end
