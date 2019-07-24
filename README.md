# Algoliax

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `algoliax` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:algoliax, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/algoliax](https://hexdocs.pm/algoliax).

### OBJECT

- [ ] save_object
- [ ] save_objects
- [ ] get_object
- [ ] delete_object
- [ ] deindex(query \\ nil)
- [ ] reindex(query \\ nil, opts \\ []) # atomic: true/false

### INDEX

- [ ] delete_index
- [ ] create_index
- [ ] configure_index
- [ ] ensure_configured
- [ ] generate_secured_api_key(object_id \\ default settings)
