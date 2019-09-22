defmodule Algoliax.RequestTest do
  use ExUnit.Case, async: true
  import Mock

  test_with_mock "test retries", :hackney, request: fn _, _, _, _, _ -> {:error, %{}} end do
    Algoliax.Request.request(
      %{action: :get_object, url_params: [index_name: :index_name, object_id: 10]},
      0
    )

    assert_called(
      :hackney.request(
        :get,
        "https://APPLICATION_ID-dsn.algolia.net/1/indexes/index_name/10",
        [{"X-Algolia-API-Key", nil}, {"X-Algolia-Application-Id", "APPLICATION_ID"}],
        "null",
        [:with_body]
      )
    )

    assert_called(
      :hackney.request(
        :get,
        "https://APPLICATION_ID-1.algolianet.com/1/indexes/index_name/10",
        [{"X-Algolia-API-Key", nil}, {"X-Algolia-Application-Id", "APPLICATION_ID"}],
        "null",
        [:with_body]
      )
    )

    assert_called(
      :hackney.request(
        :get,
        "https://APPLICATION_ID-2.algolianet.com/1/indexes/index_name/10",
        [{"X-Algolia-API-Key", nil}, {"X-Algolia-Application-Id", "APPLICATION_ID"}],
        "null",
        [:with_body]
      )
    )

    assert_called(
      :hackney.request(
        :get,
        "https://APPLICATION_ID-3.algolianet.com/1/indexes/index_name/10",
        [{"X-Algolia-API-Key", nil}, {"X-Algolia-Application-Id", "APPLICATION_ID"}],
        "null",
        [:with_body]
      )
    )
  end
end
