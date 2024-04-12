defmodule Algoliax.Assertions do
  @moduledoc false

  alias Algoliax.RequestsStore

  defmacro assert_request(method, data) do
    quote bind_quoted: [method: method, data: data] do
      body = Map.get(data, :body)
      path = Map.get(data, :path)
      headers = Map.get(data, :headers)
      requests = RequestsStore.get()

      request =
        Enum.find(requests, fn r ->
          r.method == method && equal_path?(path, r.path) &&
            body
            |> Map.keys()
            |> Enum.all?(fn k ->
              r_body = r.body[k]
              a_body = body[k]

              {res, _} = Code.eval_string("match?(#{inspect(a_body)}, #{inspect(r_body)})")
              res
            end) && has_headers?(headers, r.headers)
        end)

      case request do
        nil ->
          message =
            requests
            |> Enum.with_index()
            |> Enum.map_join("\n", fn {r, i} ->
              String.slice(
                "#{i}: method=#{r.method}, path=#{r.path}, body=#{inspect(r.body)}, headers=#{inspect(r.headers)}",
                0..500
              )
            end)

          flunk(
            "No request found for method=#{method}, path=#{inspect(path)}, body=#{inspect(body)}\n\n Found:\n" <>
              if(message == "", do: "None", else: message)
          )

        _ ->
          RequestsStore.remove(request)
          assert request
      end
    end
  end

  def has_headers?(nil, _), do: true

  def has_headers?(headers, request_headers) do
    Enum.all?(headers, &(&1 in request_headers))
  end

  def equal_path?(nil, _), do: true

  def equal_path?(path, request_path) do
    case path do
      %Regex{} -> Regex.match?(path, request_path)
      _ -> path == request_path
    end
  end
end
