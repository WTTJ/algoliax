defmodule Algoliax.Indexer do
  @moduledoc """

  ### Usage

  - `:index_name`: specificy the index where the object will be added on. **Required**
  - `:object_id`: specify the attribute used to as algolia objectID. Default `:id`.
  - `:repo`: Specify an Ecto repo to be use to fecth records. Default `nil`
  - `:cursor_field`: specify the column to be used to order and go through a given table. Default `:id`
  - `:schemas`: Specify which schemas used to populate index, Default: `[__CALLER__]`
  - `:algolia`: Any valid Algolia settings, using snake case or camel case. Ex: Algolia `attributeForFaceting` can be configured with `:attribute_for_faceting`

  On first call to Algolia, we check that the settings on Algolia are up to date.

  ### Example

      defmodule People do
        use Algoliax.Indexer,
          index_name: :people,
          object_id: :reference,
          algolia: [
            attribute_for_faceting: ["age"],
            custom_ranking: ["desc(updated_at)"]
          ]

        defstruct reference: nil, last_name: nil, first_name: nil, age: nil
      end

  ### Customize object

  By default the object contains only algolia `objectID`. To add more attributes to objects, override `build_object/1` functions to return a Map (objectID is automatically set by Algoliax)

      defmodule People do
        use Algoliax.Indexer,
          index_name: :people,
          object_id: :reference,
          algolia: [
            attribute_for_faceting: ["age"],
            custom_ranking: ["desc(updated_at)"]
          ]

        defstruct reference: nil, last_name: nil, first_name: nil, age: nil

        @impl Algoliax.Indexer
        def build_object(person) do
          %{
            age: person.age,
            last_name: person.last_name,
            first_name: person.first_name
          }
        end
      end

  ### Schemas

  `:schemas` options allows to define a list of module you want to index into the current index. By default only the module defining the indexer.

      defmodule Global do
        use Algoliax.Indexer,
          index_name: :people,
          object_id: :reference,
          schemas: [People, Animal],
          algolia: [
            attribute_for_faceting: ["age"],
            custom_ranking: ["desc(updated_at)"]
          ]

      end

    This option allows to define also the preloads use during `reindex`/`reindex_atomic` (preload on `save_object` and `save_objects` have to be done manually)

        defmodule People do
          use Algoliax.Indexer,
            index_name: :people,
            object_id: :reference,
            schemas: [
              {__MODULE__, [:animals]}
            ]
            algolia: [
              attribute_for_faceting: ["age"],
              custom_ranking: ["desc(updated_at)"]
            ]

        end

  """

  alias Algoliax.Resources.{Index, Object, Search}

  @doc """
  Search for index values

  ## Example

      iex> People.search("John")

      {:ok,
        %{
          "exhaustiveNbHits" => true,
          "hits" => [
            %{
              "_highlightResult" => %{
                "full_name" => %{
                  "fullyHighlighted" => false,
                  "matchLevel" => "full",
                  "matchedWords" => ["john"],
                  "value" => "Pierre <em>Jon</em>es"
                }
              },
              "age" => 69,
              "first_name" => "Pierre",
              "full_name" => "Pierre Jones",
              "indexed_at" => 1570908223,
              "last_name" => "Jones",
              "objectID" => "b563deb6-2a06-4428-8e5a-ca1ecc08f4e2"
            },
            %{
              "_highlightResult" => %{
                "full_name" => %{
                  "fullyHighlighted" => false,
                  "matchLevel" => "full",
                  "matchedWords" => ["john"],
                  "value" => "Glennie <em>Jon</em>es"
                }
              },
              "age" => 27,
              "first_name" => "Glennie",
              "full_name" => "Glennie Jones",
              "indexed_at" => 1570908223,
              "last_name" => "Jones",
              "objectID" => "58e8ff8d-2794-41e1-a4ef-6f8db8d432b6"
            },
            ...
          ],
      "hitsPerPage" => 20,
      "nbHits" => 16,
      "nbPages" => 1,
      "page" => 0,
      "params" => "query=john",
      "processingTimeMS" => 1,
      "query" => "john"
      }}
  """

  @callback search(query :: binary(), params :: map()) ::
              {:ok, map()} | {:not_indexable, model :: map()}

  @doc """
  Search for facet values

  ## Example
      iex> People.search_facet("age")
      {:ok,
        %{
          "exhaustiveFacetsCount" => true,
          "facetHits" => [
            %{"count" => 22, "highlighted" => "46", "value" => "46"},
            %{"count" => 21, "highlighted" => "38", "value" => "38"},
            %{"count" => 19, "highlighted" => "54", "value" => "54"},
            %{"count" => 19, "highlighted" => "99", "value" => "99"},
            %{"count" => 18, "highlighted" => "36", "value" => "36"},
            %{"count" => 18, "highlighted" => "45", "value" => "45"},
            %{"count" => 18, "highlighted" => "52", "value" => "52"},
            %{"count" => 18, "highlighted" => "56", "value" => "56"},
            %{"count" => 18, "highlighted" => "59", "value" => "59"},
            %{"count" => 18, "highlighted" => "86", "value" => "86"}
          ],
          "processingTimeMS" => 1
        }}
  """
  @callback search_facet(facet_name :: binary(), facet_query :: binary(), params :: map()) ::
              {:ok, map()} | {:not_indexable, model :: map()}

  @doc """
  Add/update object. The object is added/updated to algolia with the object_id configured.

  ## Example
      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20},

      People.save_object(people)
  """
  @callback save_object(object :: map() | struct()) ::
              {:ok, map()} | {:not_indexable, model :: map()}

  @doc """
  Save multiple object at once

  ## Options

    * `:force_delete` - if `true` will trigger a "deleteObject" on object that must not be indexed. Default `false`

  ## Example

      peoples = [
        %People{reference: 10, last_name: "Doe", first_name: "John", age: 20},
        %People{reference: 89, last_name: "Einstein", first_name: "Albert", age: 65}
      ]

      People.save_objects(peoples)
      People.save_objects(peoples, force_delete: true)
  """
  @callback save_objects(models :: list(map()) | list(struct()), opts :: Keyword.t()) ::
              {:ok, map()} | {:error, map()}

  @doc """
  Fetch object from algolia. By passing the model, the object is retreived using the object_id configured

  ## Example
      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20}

      People.get_object(people)
  """
  @callback get_object(model :: map() | struct()) :: {:ok, map()} | {:error, map()}

  @doc """
  Delete object from algolia. By passing the model, the object is retreived using the object_id configured

  ## Example
      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20}

      People.delete_object(people)
  """
  @callback delete_object(model :: map() | struct()) :: {:ok, map()} | {:error, map()}

  if Code.ensure_loaded?(Ecto) do
    @doc """
    Reindex a subset of records by providing an Ecto query or query filters as a Map([Ecto](https://hexdocs.pm/ecto/Ecto.html) specific)

    ## Example
        import Ecto.Query

        query = from(
          p in People,
          where: p.age > 45
        )

        People.reindex(query)

        # OR
        filters = %{where: [name: "john"]}
        People.reindex(filters)

    Available options:

    - `:force_delete`: delete objects that are in query and where `to_be_indexed?` is false

    > NOTE: filters as Map supports only `:where` and equality
    """
    @callback reindex(query :: Ecto.Query.t(), opts :: Keyword.t()) :: {:ok, :completed}

    @doc """
    Reindex all objects ([Ecto](https://hexdocs.pm/ecto/Ecto.html) specific)

    ## Example

        People.reindex(query)

    Available options:

    - `:force_delete`: delete objects where `to_be_indexed?` is `false`
    """
    @callback reindex(opts :: Keyword.t()) :: {:ok, :completed}

    @doc """
    Reindex atomicly ([Ecto](https://hexdocs.pm/ecto/Ecto.html) specific)
    """
    @callback reindex_atomic() :: {:ok, :completed}
  end

  @doc """
  Build the object sent to algolia. By default the object contains only `objectID` set by Algoliax.Indexer

  ## Example
      @impl Algoliax.Indexer
      def build_object(person) do
        %{
          age: person.age,
          last_name: person.last_name,
          first_name: person.first_name
        }
      end
  """
  @callback build_object(model :: Map.t()) :: Map.t()

  @doc """
  Check if current object must be indexed or not. By default it's always true. To override this behaviour overide this function in your model

  ## Example

      defmodule People do
        use Algoliax.Indexer,
          index_name: :people,
          object_id: :reference,
          algolia: [
            attribute_for_faceting: ["age"],
            custom_ranking: ["desc(update_at)"]
          ]

        #....

        @impl Algoliax.Indexer
        def to_be_indexed?(model) do
          model.age > 50
        end
      end
  """
  @callback to_be_indexed?(model :: map()) :: true | false

  @doc """
  Override this function to provide custom objectID for the model

  ## Example
      @impl Algoliax.Indexer
      def get_object_id(%Cat{id: id}), do: "Cat:" <> to_string(id)
      def get_object_id(%Dog{id: id}), do: "Dog:" <> to_string(id)
  """
  @callback get_object_id(model :: map()) :: binary() | :default

  @doc """
  Get index settings from Algolia
  """
  @callback get_settings() :: {:ok, map()} | {:error, map()}

  @doc """
  Configure index
  """
  @callback configure_index() :: {:ok, map()} | {:error, map()}

  @doc """
  Delete index
  """
  @callback delete_index() :: {:ok, map()} | {:error, map()}

  defmacro __using__(settings) do
    quote do
      @behaviour Algoliax.Indexer

      settings = unquote(settings)
      @settings settings

      @impl Algoliax.Indexer
      def search(query, params \\ %{}) do
        Search.search(__MODULE__, @settings, query, params)
      end

      @impl Algoliax.Indexer
      def search_facet(facet_name, facet_query \\ nil, params \\ %{}) do
        Search.search_facet(__MODULE__, @settings, facet_name, facet_query, params)
      end

      @impl Algoliax.Indexer
      def get_settings do
        Index.get_settings(__MODULE__, @settings)
      end

      @impl Algoliax.Indexer
      def configure_index do
        Index.configure_index(__MODULE__, @settings)
      end

      @impl Algoliax.Indexer
      def delete_index do
        Index.delete_index(__MODULE__, @settings)
      end

      @impl Algoliax.Indexer
      def save_objects(models, opts \\ []) do
        Object.save_objects(__MODULE__, @settings, models, opts)
      end

      @impl Algoliax.Indexer
      def save_object(model) do
        Object.save_object(__MODULE__, @settings, model)
      end

      @impl Algoliax.Indexer
      def delete_object(model) do
        Object.delete_object(__MODULE__, @settings, model)
      end

      @impl Algoliax.Indexer
      def get_object(model) do
        Object.get_object(__MODULE__, @settings, model)
      end

      if Code.ensure_loaded?(Ecto) do
        alias Algoliax.Resources.ObjectEcto

        @impl Algoliax.Indexer
        def reindex(opts) when is_list(opts) do
          ObjectEcto.reindex(__MODULE__, @settings, %{}, opts)
        end

        @impl Algoliax.Indexer
        def reindex(query) when is_map(query) do
          ObjectEcto.reindex(__MODULE__, @settings, query, [])
        end

        @impl Algoliax.Indexer
        def reindex(query \\ nil, opts \\ []) do
          ObjectEcto.reindex(__MODULE__, @settings, query, opts)
        end

        @impl Algoliax.Indexer
        def reindex_atomic do
          ObjectEcto.reindex_atomic(__MODULE__, @settings)
        end
      end

      @impl Algoliax.Indexer
      def build_object(_) do
        %{}
      end

      @impl Algoliax.Indexer
      def to_be_indexed?(_) do
        true
      end

      @impl Algoliax.Indexer
      def get_object_id(_) do
        :default
      end

      defoverridable(to_be_indexed?: 1, build_object: 1, get_object_id: 1)
    end
  end
end
