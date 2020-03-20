defmodule Algoliax.Indexer do
  @moduledoc """

  ### Usage

  - `:index_name`: specificy the index where the object will be added on. **Required**
  - `:object_id`: specify the attribute used to as algolia objectID. Default `:id`.
  - `:repo`: Specify an Ecto repo to be use to fecth records. Default `nil`
  - `:preloads`: Specify preloads for a given schema. Default `[]`
  - `:cursor_field`: specify the column to be used to order and go through a given table. Default `:id`
  - `:prepare_object`: Specify a function of arity 2 to call after building the object. Default `nil`
  - `:schemas`: Specify which schemas used to populate index (attributes not used), Default: `[]`
  - `:algolia`: Any valid Algolia settings, using snake case or camel case. Ex: Algolia `attributeForFaceting` can be configured with `:attribute_for_faceting`

  On first call to Algolia, we check that the settings on Algolia are up to date.

  ### Attributes

  Objects send to Algolia are built using the attributes defined in the module using `attribute/1`, `attributes/1` or `attribute/2`

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

        attributes([:first_name, :last_name, :age])

        attribute(:updated_at, ~U[2019-07-18 08:45:56.639380Z] |> DateTime.to_unix())

        attribute :full_name do
          Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
        end

        attribute :nickname do
          Map.get(model, :first_name, "") |> String.downcase()
        end
      end
  """

  alias Algoliax.Utils
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

  @doc """
  Reindex a part of object by providing an Ecto query ([Ecto](https://hexdocs.pm/ecto/Ecto.html) specific)

  ## Example
      import Ecto.Query

      query = from(
        p in People,
        where: p.age > 45
      )

      People.reindex(query)

  Available options:

  - `:force_delete`: delete objects that are in query and where `to_be_indexed?` is false
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

        def to_be_indexed?(model) do
          model.age > 50
        end
      end
  """
  @callback to_be_indexed?(model :: map()) :: true | false

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

      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :index_attributes, accumulate: true)

      settings = unquote(settings)
      @settings settings

      @before_compile unquote(__MODULE__)

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
      def to_be_indexed?(model) do
        true
      end

      defoverridable(to_be_indexed?: 1)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl Algoliax.Indexer
      def save_objects(models, opts \\ []) do
        Object.save_objects(
          __MODULE__,
          @settings,
          models,
          @index_attributes,
          opts
        )
      end

      @impl Algoliax.Indexer
      def save_object(model) do
        Object.save_object(__MODULE__, @settings, model, @index_attributes)
      end

      @impl Algoliax.Indexer
      def delete_object(model) do
        Object.delete_object(__MODULE__, @settings, model, @index_attributes)
      end

      @impl Algoliax.Indexer
      def get_object(model) do
        Object.get_object(__MODULE__, @settings, model, @index_attributes)
      end

      @impl Algoliax.Indexer
      def reindex(opts) when is_list(opts) do
        Object.reindex(__MODULE__, @settings, @index_attributes, nil, opts)
      end

      if Code.ensure_loaded?(Ecto) do
        @impl Algoliax.Indexer
        def reindex(query \\ nil, opts \\ []) do
          Object.reindex(__MODULE__, @settings, @index_attributes, query, opts)
        end

        @impl Algoliax.Indexer
        def reindex_atomic do
          Object.reindex_atomic(__MODULE__, @settings, @index_attributes)
        end
      end
    end
  end

  @doc """
  Define an attributes to be indexed with a computed value without or with model access

  ## Example without model access

  The model is not available.

      attribute :utc_now, DateTime.utc_now()

  ## Example with model access

  The model is available inside the block.

      attribute :uppcase_name do
        model.name |> String.upcase()
      end
  """
  defmacro attribute(attribute_name, do: block) do
    method_attribute_name = Utils.prefix_attribute(attribute_name)

    quote do
      @index_attributes unquote(method_attribute_name)
      def unquote(method_attribute_name)(model) do
        var!(model) = model
        unquote(block)
      end
    end
  end

  defmacro attribute(attribute_name, value) do
    method_attribute_name = Utils.prefix_attribute(attribute_name)

    quote do
      @index_attributes unquote(method_attribute_name)
      def unquote(method_attribute_name)(model) do
        unquote(value)
      end
    end
  end

  @doc """
  Define an attribute to be added to the indexed object with a value taken from the model (map/struct)

  ## Example

      attribute :id
  """
  defmacro attribute(attribute_name) do
    build_attribute(attribute_name)
  end

  @doc """
  Define multiple attributes to be added to the indexed object with a value taken from the model (map/struct)

  ## Example

      attributes :id, :inserted_at
  """
  defmacro attributes(attribute_names) do
    Enum.map(attribute_names, fn attribute_name ->
      build_attribute(attribute_name)
    end)
  end

  @doc false
  def build_attribute(attribute_name) do
    method_attribute_name = Utils.prefix_attribute(attribute_name)

    quote do
      @index_attributes unquote(method_attribute_name)
      def unquote(method_attribute_name)(model) do
        Map.get(model, unquote(attribute_name))
      end
    end
  end
end
