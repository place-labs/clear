require "spec"
require "json"
require "big"

require "../../src/clear/error_messages"
require "../../src/clear/extensions/openapi"

struct Model
  extend OpenAPI::Generator::Serializable
  include JSON::Serializable

  property string : String
  @[OpenAPI::Field(read_only: true)]
  property opt_string : String?
  property inner_schema : InnerModel
  @[OpenAPI::Field(ignore: true)]
  property ignored : Nil
  @[OpenAPI::Field(type: String, example: "1")]
  @cast : Int32

  def cast
    @cast.to_s
  end

  SCHEMA = <<-JSON
  {
    "required": [
      "string",
      "inner_schema",
      "cast"
    ],
    "type": "object",
    "properties": {
      "string": {
        "type": "string"
      },
      "opt_string": {
        "type": "string",
        "readOnly": true
      },
      "inner_schema": {
        "$ref": "#/components/schemas/Model_InnerModel"
      },
      "cast": {
        "type": "string",
        "example": "1"
      }
    }
  }
  JSON

  struct InnerModel
    extend OpenAPI::Generator::Serializable
    include JSON::Serializable

    @[OpenAPI::Field(write_only: true)]
    property array_of_int : Array(Int32)

    SCHEMA = <<-JSON
    {
      "required": [
        "array_of_int"
      ],
      "type": "object",
      "properties": {
        "array_of_int": {
          "type": "array",
          "items": {
            "type": "integer"
          },
          "writeOnly": true
        }
      }
    }
    JSON
  end

  struct ComplexModel
    extend OpenAPI::Generator::Serializable
    include JSON::Serializable

    property union_types : Int32 | String | Hash(String, InnerModel)
    property free_form : JSON::Any
    property array_of_hash : Array(Hash(String, Int32 | String))

    SCHEMA = <<-JSON
    {
      "required": [
        "union_types",
        "free_form",
        "array_of_hash"
      ],
      "type": "object",
      "properties": {
        "union_types": {
          "oneOf": [
            {
              "type": "object",
              "additionalProperties": {
                "$ref": "#/components/schemas/Model_InnerModel"
              }
            },
            {
              "type": "integer"
            },
            {
              "type": "string"
            }
          ]
        },
        "free_form": {
          "type": "object",
          "additionalProperties": true
        },
        "array_of_hash": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": {
              "oneOf": [
                {
                  "type": "integer"
                },
                {
                  "type": "string"
                }
              ]
            }
          }
        }
      }
    }
    JSON
  end
end

class ClearModelExample
  include Clear::Model
  extend OpenAPI::Generator::Serializable

  column id : Int64, primary: true, mass_assign: false, example: "123"
  column email : String, mass_assign: true, example: "default@gmail.com"
end

struct ClearModelExampleCopy
  extend OpenAPI::Generator::Serializable
  include JSON::Serializable

  @[OpenAPI::Field(read_only: true, example: "123")]
  property id : Int64

  @[OpenAPI::Field(write_only: true, example: "default@gmail.com")]
  property email : String
end

describe OpenAPI::Generator::Serializable do
  it "should serialize an object into an openapi schema if it has not included Clear::Model" do
    json_schema = ::Model.generate_schema.to_pretty_json
    json_schema.should eq ::Model::SCHEMA

    inner_schema = ::Model::InnerModel.generate_schema.to_pretty_json
    inner_schema.should eq ::Model::InnerModel::SCHEMA

    json_schema = ::Model::ComplexModel.generate_schema.to_pretty_json
    json_schema.should eq ::Model::ComplexModel::SCHEMA
  end

  it "should serialize a Clear Model into an openapi schema" do
    json_schema = ::ClearModelExample.generate_schema.to_pretty_json
    json_schema_copy = ClearModelExampleCopy.generate_schema.to_pretty_json
    json_schema.should eq(json_schema_copy)
  end
end
