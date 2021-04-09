require "../../clear"
require "openapi-generator"

module OpenAPI::Generator::Serializable
  # Serialize the class into an `OpenAPI::Schema` representation.
  #
  # Check the [swagger documentation](https://swagger.io/docs/specification/data-models/) for more details
  def generate_schema
    schema = OpenAPI::Schema.new(
      type: "object",
      properties: Hash(String, (OpenAPI::Schema | OpenAPI::Reference)).new,
      required: [] of String
    )

    # For every instance variable in this Class
    {% if Clear::Model.includers.includes?(@type) %}
      \{% for name, settings in @type.constant("COLUMNS") %}
        \{% types = settings[:type].resolve.union_types %}
        \{% schema_key = settings["crystal_variable_name"].id %}
        \{% as_type = settings["openapi"] && settings["openapi"]["type"] && settings["openapi"]["type"].types.map(&.resolve) %}
        \{% read_only = settings["openapi"] && settings["openapi"]["read_only"] %}
        \{% write_only = settings["openapi"] && settings["openapi"]["write_only"] %}
        \{% example = settings["openapi"] && settings["openapi"]["example"] %}

        ::OpenAPI::Generator::Serializable.generate_schema(
          schema,
          types: \{{types}},
          schema_key: \{{schema_key}},
          as_type: \{{as_type}},
          read_only: \{{read_only}},
          write_only: \{{write_only}},
          example: \{{example}}
        )
      \{% end %}
      # If not a Clear Model
    {% else %}
      \{% for ivar in @type.instance_vars %}
        \{% json_ann = ivar.annotation(JSON::Field) %}
        \{% openapi_ann = ivar.annotation(OpenAPI::Field) %}
        \{% types = ivar.type.union_types %}
        \{% schema_key = json_ann && json_ann[:key] || ivar.id %}
        \{% as_type = openapi_ann && openapi_ann[:type] && openapi_ann[:type].types.map(&.resolve) %}
        \{% read_only = openapi_ann && openapi_ann[:read_only] %}
        \{% write_only = openapi_ann && openapi_ann[:write_only] %}
        \{% example = openapi_ann && openapi_ann[:example] %}

        \{% unless json_ann && json_ann[:ignore] %}
          ::OpenAPI::Generator::Serializable.generate_schema(
            schema,
            types: \{{types}},
            schema_key: \{{schema_key}},
            as_type: \{{as_type}},
            read_only: \{{read_only}},
            write_only: \{{write_only}},
            example: \{{example}}
          )
        \{% end %}
      \{% end %}
    {% end %}
    schema
  end
end
