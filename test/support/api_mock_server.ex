defmodule Algoliax.ApiMockServer do
  @moduledoc false

  use Plug.Router
  use Plug.ErrorHandler

  alias Algoliax.RequestsStore

  import Plug.Conn

  plug(Plug.Parsers,
    parsers: [:json, :urlencoded],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:save_request)
  plug(:dispatch)

  # Search index (POST): https://www.algolia.com/doc/rest-api/search/#search-index-post
  post "/:application_id/:mode/:index_name/query" do
    response = search_response()
    send_resp(conn, 200, Jason.encode!(response))
  end

  # Search index (POST): https://www.algolia.com/doc/rest-api/search/#search-index-post
  post "/:application_id/:mode/:index_name/facets/:facet_name/query" do
    response = search_facet_response()
    send_resp(conn, 200, Jason.encode!(response))
  end

  # get settings: https://www.algolia.com/doc/rest-api/search/#get-settings
  get "/:application_id/:mode/:index_name/settings" do
    response = %{
      searchableAttributes: ["test"]
    }

    send_resp(conn, 200, Jason.encode!(response))
  end

  # set settings: https://www.algolia.com/doc/rest-api/search/#set-settings
  put "/:application_id/:mode/:index_name/settings" do
    response = %{
      updatedAt: DateTime.utc_now(),
      taskID: :rand.uniform(10000)
    }

    send_resp(conn, 200, Jason.encode!(response))
  end

  # Add/update object (with ID): https://www.algolia.com/doc/rest-api/search/#addupdate-object-with-id
  put "/:application_id/:mode/:index_name/:object_id" do
    response = %{
      updatedAt: DateTime.utc_now(),
      taskID: :rand.uniform(10000),
      objectID: Map.get(conn.params, "object_id")
    }

    send_resp(conn, 200, Jason.encode!(response))
  end

  # Batch write operations: https://www.algolia.com/doc/rest-api/search/#batch-write-operations
  post "/:application_id/:mode/:index_name/batch" do
    requests = conn.body_params["requests"]

    objectIDs =
      Enum.map(requests, fn request ->
        request["body"]["objectID"]
        |> to_string()
      end)

    response = %{
      taskID: :rand.uniform(10000),
      objectIDs: objectIDs
    }

    send_resp(conn, 200, Jason.encode!(response))
  end

  # Copy/move index: https://www.algolia.com/doc/rest-api/search/#copymove-index
  post "/:application_id/:mode/:index_name/operation" do
    response = %{
      updatedAt: "2013-01-18T15:33:13.556Z",
      taskID: 681
    }

    send_resp(conn, 200, Jason.encode!(response))
  end

  # Get object: https://www.algolia.com/doc/rest-api/search/#get-object
  get "/:application_id/:mode/:count/:index_name/:object_id" do
    case Map.get(conn.params, "object_id") do
      "known" ->
        response = %{
          objectID: Map.get(conn.params, "object_id")
        }

        send_resp(conn, 200, Jason.encode!(response))

      "error" ->
        send_resp(conn, 500, "Internal server error :(")

      _ ->
        send_resp(conn, 404, Jason.encode!(%{}))
    end
  end

  get "/:application_id/:mode/:index_name/:object_id" do
    case Map.get(conn.params, "object_id") do
      "known" ->
        response = %{
          objectID: Map.get(conn.params, "object_id")
        }

        send_resp(conn, 200, Jason.encode!(response))

      "error" ->
        send_resp(conn, 500, "Internal server error :(")

      _ ->
        send_resp(conn, 404, Jason.encode!(%{}))
    end
  end

  # Delete object: https://www.algolia.com/doc/rest-api/search/#delete-object
  delete "/:application_id/:mode/:index_name/:object_id" do
    response = %{
      deletedAt: "2013-01-18T15:33:13.556Z",
      taskID: 681
    }

    send_resp(conn, 200, Jason.encode!(response))
  end

  # delete index: https://www.algolia.com/doc/rest-api/search/#delete-index
  delete "/:application_id/:mode/:index_name" do
    send_resp(conn, 200, Jason.encode!(%{}))
  end

  match _ do
    IO.inspect(conn)
    send_resp(conn, 404, "oops")
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Something went wrong")
  end

  defp save_request(conn, _) do
    RequestsStore.save(%{
      id: :rand.uniform(100_000),
      method: conn.method,
      path: conn.request_path,
      body: conn.body_params
    })

    conn
  end

  defp search_response do
    %{
      hits: [
        %{
          name: "George Clooney",
          objectID: "2051967",
          _highlightResult: %{
            name: %{
              value: "<em>George</em> <em>Clo</em>oney",
              matchLevel: "full"
            }
          },
          _snippetResult: %{
            bio: %{
              value: "is the son of <em>George</em> <em>Clo</em>oney as was his father"
            }
          },
          _rankingInfo: %{
            nbTypos: 0,
            firstMatchedWord: 0,
            proximityDistance: 1,
            userScore: 5,
            geoDistance: 0,
            geoPrecision: 1,
            nbExactWords: 0
          }
        },
        %{
          name: "George Clooney's Irish Roots",
          year: "(2012 Documentary)",
          objectID: "825416",
          _highlightResult: %{
            name: %{
              value: "<em>George</em> <em>Clo</em>oney's Irish Roots",
              matchLevel: "full"
            },
            year: %{
              value: "(2012 Documentary)",
              matchLevel: "none"
            }
          },
          _rankingInfo: %{
            nbTypos: 0,
            firstMatchedWord: 0,
            proximityDistance: 1,
            userScore: 4,
            geoDistance: 0,
            geoPrecision: 1,
            nbExactWords: 0
          }
        }
      ],
      page: 0,
      nbHits: 38,
      nbPages: 19,
      hitsPerPage: 2,
      processingTimeMS: 6,
      query: "george clo",
      parsed_query: "george clo",
      params: "query=george%20clo&hitsPerPage=2&getRankingInfo=1"
    }
  end

  defp search_facet_response do
    %{
      facetHits: [
        %{
          value: "Mobile phones",
          highlighted: "Mobile <em>phone</em>s",
          count: 507
        },
        %{
          value: "Phone cases",
          highlighted: "<em>Phone</em> cases",
          count: 63
        }
      ]
    }
  end
end
