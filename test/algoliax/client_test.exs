defmodule Algoliax.ClientTest do
  use Algoliax.RequestCase

  test "test retries" do
    api_key = "api_key"
    application_id = "APPLICATION_ID"

    Algoliax.Client.request(
      %{
        action: :get_object,
        api_key: api_key,
        application_id: application_id,
        url_params: [
          application_id: application_id,
          index_name: :index_name,
          object_id: "error"
        ]
      },
      0
    )

    assert_request("GET", %{path: "/APPLICATION_ID/read/index_name/error", body: %{}})
    assert_request("GET", %{path: "/APPLICATION_ID/retry/1/index_name/error", body: %{}})
    assert_request("GET", %{path: "/APPLICATION_ID/retry/2/index_name/error", body: %{}})
    assert_request("GET", %{path: "/APPLICATION_ID/retry/3/index_name/error", body: %{}})
  end

  test "Error http" do
    api_key = "api_key_invalid"
    application_id = "APPLICATION_ID"

    message = """
    Algolia HTTP error:

    403 : Index not allowed with this API key
    """

    assert_raise(Algoliax.AlgoliaApiError, message, fn ->
      Algoliax.Client.request(
        %{
          action: :get_object,
          api_key: api_key,
          application_id: application_id,
          url_params: [
            application_id: application_id,
            index_name: :index_name_not_authorized,
            object_id: "Whatever"
          ]
        },
        0
      )
    end)
  end
end
