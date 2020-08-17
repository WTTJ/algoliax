defmodule Algoliax.Assertions do
  @moduledoc false

  alias Algoliax.RequestsStore

  defmacro assert_request(method, path, body) do
    assert(method, path, body)
  end

  defmacro assert_request(method, body) do
    assert(method, nil, body)
  end

  defp assert(method, path, body) do
    quote bind_quoted: [method: method, path: path, body: body] do
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
            end)
        end)

      case request do
        nil ->
          message =
            requests
            |> Enum.with_index()
            |> Enum.map(fn {r, i} ->
              String.slice(
                "#{i}: method=#{r.method}, path=#{r.path}, body=#{inspect(r.body)}",
                0..500
              )
            end)
            |> Enum.join("\n")

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

  def equal_path?(nil, _), do: true

  def equal_path?(path, request_path) do
    if Regex.regex?(path) do
      Regex.match?(path, request_path)
    else
      path == request_path
    end
  end
end
