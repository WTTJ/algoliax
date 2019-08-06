defmodule Algoliax do
  @moduledoc """
  Algoliax is wrapper for Algolia api

  ### Configuration

  Algoliax needs only `:api_key` and `application_id` config. These configs can either be on config files or using environment varialble `"ALGOLIA_API_KEY"` and `"ALGOLIA_APPLICATION_ID"`.

      config :algoliax,
        api_key: "",
        application_id: ""

  ### Usage

  - `:index_name`, specificy the index where the object will be added on. **Required**
  - `:object_id`, specify the attribute used to as algolia objectID. Default `:id`.

  Any valid Algolia settings, using snake case. Ex: Algolia `attributeForFaceting` will be configured with `:attribute_for_faceting`

  On first call to Algolia, we check that the settings on Algolia are up to date.

  ### Attributes

  Objects send to Algolia are built using the attributes defined in the module using `attribute/1`, `attributes/1` or `attribute/2`

  ### Example

      defmodule People do
        use Algoliax,
          index_name: :people,
          object_id: :reference,
          attribute_for_faceting: ["age"],
          custom_ranking: ["desc(update_at)"]

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
  alias Algoliax.Resources.{Index, Object}
  alias Algoliax.{Config, Utils}

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
      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20},

      People.get_object(people)
  """
  @callback get_object(model :: map() | struct()) :: {:ok, map()} | {:error, map()}

  @doc """
  Delete object from algolia. By passing the model, the object is retreived using the object_id configured

  ## Example
      people = %People{reference: 10, last_name: "Doe", first_name: "John", age: 20},

      People.delete_object(people)
  """
  @callback delete_object(model :: map() | struct()) :: {:ok, map()} | {:error, map()}

  @doc """
  Reindex [Ecto](https://hexdocs.pm/ecto/Ecto.html) specific
  """
  @callback reindex(query :: Ecto.Query.t()) :: {:ok, map()} | {:error, map()}

  @doc """
  Reindex atomicly [Ecto](https://hexdocs.pm/ecto/Ecto.html) specific
  """
  @callback reindex_atomic() :: {:ok, map()} | {:error, map()}

  @doc """
  Check if current object can be indexed or not. By default it's always true. To override this behaviour overide this function in your model

  ## Example

      defmodule People do
        use Algoliax,
          index_name: :people,
          attribute_for_faceting: ["age"],
          custom_ranking: ["desc(update_at)"],
          object_id: :reference

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
      @behaviour Algoliax

      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :index_attributes, accumulate: true)

      settings = unquote(settings)
      @settings settings

      @before_compile unquote(__MODULE__)

      @impl Algoliax
      def get_settings do
        Index.get_settings(@settings)
      end

      @impl Algoliax
      def configure_index do
        Index.configure_index(@settings)
      end

      @impl Algoliax
      def delete_index do
        Index.delete_index(@settings)
      end

      @impl Algoliax
      def to_be_indexed?(model) do
        true
      end

      defoverridable(to_be_indexed?: 1)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl Algoliax
      def save_objects(models, opts \\ []) do
        Object.save_objects(
          @settings,
          __MODULE__,
          models,
          @index_attributes,
          opts
        )
      end

      @impl Algoliax
      def save_object(model) do
        apply(__MODULE__, :to_be_indexed?, [model])
        Object.save_object(@settings, __MODULE__, model, @index_attributes)
      end

      @impl Algoliax
      def delete_object(model) do
        Object.delete_object(@settings, __MODULE__, model, @index_attributes)
      end

      @impl Algoliax
      def get_object(model) do
        Object.get_object(@settings, __MODULE__, model, @index_attributes)
      end

      @impl Algoliax
      def reindex(query \\ nil) do
        Object.reindex(@settings, __MODULE__, @index_attributes, query)
      end

      @impl Algoliax
      def reindex_atomic do
        Object.reindex_atomic(@settings, __MODULE__, @index_attributes)
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
    Algoliax.build_attribute(attribute_name)
  end

  @doc """
  Define multiple attributes to be added to the indexed object with a value taken from the model (map/struct)

  ## Example

      attributes :id, :inserted_at
  """
  defmacro attributes(attribute_names) do
    Enum.map(attribute_names, fn attribute_name ->
      Algoliax.build_attribute(attribute_name)
    end)
  end

  @doc """
  Generate a secured api key with filter

  ## Examples

      Algoliax.generate_secured_api_key("reference:10")
      Algoliax.generate_secured_api_key("reference:10 OR nickname:john")
  """
  @spec generate_secured_api_key(filters :: binary()) :: binary()
  def generate_secured_api_key(filters) do
    query_string = "filters=#{URI.encode_www_form("#{filters}")}"

    hmac =
      :crypto.hmac(
        :sha256,
        Config.api_key(),
        query_string
      )
      |> Base.encode16(case: :lower)

    Base.encode64(hmac <> query_string)
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
