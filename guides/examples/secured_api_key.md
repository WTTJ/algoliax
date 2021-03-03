# Generate a secured api key

**NOTE**: Make sure to use a Search only api_key to genrate secured api key.

[See on algolia](https://www.algolia.com/doc/guides/security/api-keys/how-to/user-restricted-access-to-data/#generating-a-secured-api-key)

Algoliax allows to generate secured api key for example restrict access to a given user:

```json
[
  {
    "title": "Catch Me If You Can",
    "kind": "biography",
    "objectID": "myID1"
  },
  {
    "title": "The island",
    "kind": "drama",
    "objectID": "myID2"
  },
  {
    "title": "Good Will Hunting",
    "kind": "drama",
    "objectID": "myID3"
  },
  {
    "title": "Ferdinand",
    "kind": "animation",
    "objectID": "myID4"
  }
]
```

Valid params are `:filters`, `:validUntil`, `:restrictIndices`, `:restrictSources` and `:userToken`.

```elixir
# restrict access to drama movies
{:ok, key} = Algoliax.generate_secured_api_key("api_key", %{filters: "kind:drama"})

# restrict access to drama and animation movies
{:ok, key} = Algoliax.generate_secured_api_key("api_key", %{filters: "kind:drama OR kind:animation"})

# invalid params
{:error, :invalid_params} = Algoliax.generate_secured_api_key("api_key", %{whatever: "test:10"})
```

Moreover it's recommended to set the `:validUntil` params, so the key automatically expires after some time. It avoids having to delete the base key

```elixir
# restrict access to drama movies and expires in one hour
valid_until = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
{:ok, key} = Algoliax.generate_secured_api_key("api_key", %{filters: "kind:drama", validUntil: valid_until})
```
