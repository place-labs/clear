require "../spec_helper"

module ConverterSpec
  describe "Clear::Model::Converter::TimeConverter" do
    it "converts nil" do
      converter = Clear::Model::Converter::TimeConverter
      converter.to_column(nil).should eq(nil)
    end

    it "converts a time object" do
      converter = Clear::Model::Converter::TimeConverter
      time_obj = Time.local
      converter.to_column(time_obj).should eq(time_obj)
    end

    it "converts date formated like 2020-02-22 09:11:42.476953" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-22 09:11:42.476953"
      time_obj = Time.parse_local(example_date, "%F %X.%L")
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-22T09:11:42.476953Z" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-22T09:11:42.476953Z"
      time_obj = Time.parse(example_date, "%FT%X.%6NZ", Time::Location::UTC)
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-22T09:11:42Z" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-22T09:11:42Z"
      time_obj = Time.parse(example_date, "%FT%XZ", Time::Location::UTC)
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-24T11:05:28+07:00" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-24T11:05:28+07:00"
      time_obj = Time.parse!(example_date, "%FT%X%z")
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-11T17:54:49.000Z" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-11T17:54:49.000Z"
      time_obj = Time.parse(example_date, "%FT%X.%LZ", Time::Location::UTC)
      converter.to_column(example_date).should eq(time_obj)
    end
  end
  describe "Clear::Model::Converter::BoolConverter" do
    it "convert from boolean" do
      converter = Clear::Model::Converter::BoolConverter
      converter.to_column(1).should eq(true)
      converter.to_column(-1).should eq(true)
      converter.to_column(0).should eq(false)
      converter.to_column(0.0).should eq(false)
      converter.to_column(2).should eq(true)
      converter.to_column(1.0).should eq(true)

      converter.to_column(true).should eq(true)
      converter.to_column(false).should eq(false)

      converter.to_column("f").should eq(false)
      converter.to_column("t").should eq(true)
      converter.to_column("false").should eq(false)
      converter.to_column("true").should eq(true)

      converter.to_column(nil).should eq(nil)

      # Anything else than string or number is true
      converter.to_column([] of String).should eq(true)
    end

    it "transform boolean to 't' and 'f'" do
      converter = Clear::Model::Converter::BoolConverter
      converter.to_db(true).should eq("t")
      converter.to_db(false).should eq("f")
      # To ensure we can use the converter with Bool? type.
      converter.to_db(nil).should eq(nil)
    end

    it "converts from uuid" do
      converter = Clear::Model::Converter::UUIDConverter
      some_uuid = UUID.random
      converter.to_db(some_uuid).should eq(some_uuid.to_s)
      converter.to_db(nil).should eq(nil)
    end
  end

  class House
    include Clear::Model
    column id : Int64, primary: true, presence: false
    column rooms : Hash(String, Int32), converter: "Hash(String, Int32)"
    column available : Bool?
  end

  module Clear::Model::Converter::CountsConverter
    def self.to_column(x) : Hash(String, Int32)?
      case x
      when Nil
        nil
      when ::JSON::Any
        x.as_h?.try do |hash|
          counts = hash.transform_values &.as_i?
          counts.has_value?(nil) ? nil : counts.compact
        end
      when Hash(String, Int32)
        x
      else
        raise "Cannot convert from #{x.class} to Hash(String, Int32)"
      end
    end

    def self.to_db(x : Hash(String, Int32)?) : Clear::SQL::Any
      x.to_json
    end
  end

  Clear::Model::Converter.add_converter("Hash(String, Int32)", Clear::Model::Converter::CountsConverter)
  Clear::Model::Converter.add_converter("Hash(String, Int32) | Nil", Clear::Model::Converter::CountsConverter)

  describe "Unregistered Type Clear::Model::Converter" do
    it "should create a new model with a field from a new converter with a new type" do
      body = {
        "rooms" => {
          "bed"     => 4,
          "bath"    => 3,
          "kitchen" => 1,
        },
        "available" => true,
      }
      house = House.new(body)
      house.rooms.should eq(body["rooms"])
      house.available.should eq(true)
    end
  end
end
