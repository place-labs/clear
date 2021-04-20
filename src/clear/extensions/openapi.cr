require "../../clear"
require "openapi-generator"

# The `Serializable` module automatically generates an OpenAPI Operations representation of the class or struct when extended.
#
# ### Example
#
# ```
# class ClearModelExample
#   include Clear::Model
#   extend OpenAPI::Generator::Serializable

#   column id : Int64, primary: true, mass_assign: false, example: "123"
#   column email : String, mass_assign: true, example: "default@gmail.com"
# end
# # => {
# #     "required": [
# #       "id",
# #       "email"
# #     ],
# #     "type": "object",
# #     "properties": {
# #       "id": {
# #         "type": "integer",
# #         "readOnly": true,
# #         "example": "123"
# #       },
# #       "email": {
# #         "type": "string",
# #         "writeOnly": true,
# #         "example": "default@gmail.com"
# #       }
# #     }
# #   }
# ```
#
# ### Usage
#
# Extending this module adds a `self.to_openapi_schema` that returns an OpenAPI representation
# inferred from the shape of the class or struct.
#
# The class name is also registered as a global [component schema](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#components-object)
# and will be available for referencing from any `Controller` annotation from a [reference object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#referenceObject).
#
# **See:** `OpenAPI::Generator::Controller::Schema.ref`
#
# NOTE: **Calling `to_openapi_schema` programatically is unnecessary.
# The `Generator` will take care of serialization while producing the openapi yaml file.**
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
        \{% example = settings["example"] %}

        ::OpenAPI::Generator::Serializable.generate_schema(
          schema,
          types: \{{types}},
          schema_key: \{{schema_key}},
          read_only: \{{!settings["mass_assign"]}},
          write_only: \{{settings["write_only"]}},
          example: \{{example}}
        )
      \{% end %}
      # If not a Clear Model
    {% else %}
      \{% for ivar in @type.instance_vars %}
        \{% json_ann = ivar.annotation(JSON::Field) %}
        \{% openapi_ann = ivar.annotation(OpenAPI::Field) %}
        \{% types = ivar.type.union_types %}
        \{% schema_key = json_ann && json_ann[:key] && json_ann[:key].id || ivar.id %}
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

require "./enum"

abstract struct Clear::Enum
  # :nodoc:
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      title: {{@type.name.id.stringify.split("::").join("_")}},
      type: "string",
      enum: self.authorized_values
    )
  end
end
