require "scale/version"

require "substrate_common"
require "json"
require "active_support"
require 'active_support/core_ext/string'
require 'singleton'

require "scale/base"
require "scale/types"

require "metadata/metadata"
require "metadata/metadata_v3"
require "metadata/metadata_v7"
require "metadata/metadata_v8"
require "metadata/metadata_v9"
require "metadata/metadata_v10"

module Scale
  class Error < StandardError; end

  class TypeRegistry
    include Singleton
    attr_reader :types

    def initialize
      @types = load_types
    end

    def get(type_name, chain_spec = "default")
      @types[chain_spec][type_name]
    end

    private 
    def load_types
      specs = {}

      coded_types = Scale::Types
        .constants
        .select { |c| Scale::Types.const_get(c).is_a? Class }
        .map { |type_name| [type_name.to_s, type_name.to_s] }
        .to_h
        .transform_values {|type| Scale::Types.constantize(type) }

      default_file = File.join File.expand_path('../..', __FILE__), "lib", "type_registry", "default.json"
      default_types = load_chain_spec_types(default_file).transform_values do |type|
        Scale::Types.type_convert(type, coded_types)
      end
      specs["default"] = coded_types.merge(default_types)

      # chain specs
      path = File.join File.expand_path('../..', __FILE__), "lib", "type_registry", "*.json"
      chain_specs = Dir[path]
        .reject {|file| file.end_with?("default.json") }
        .map {|file| [File.basename(file, ".json"), file] }
        .to_h
        .transform_values {|file| load_chain_spec_types(file) }
        .transform_values do |chain_types|
          chain_types.transform_values do |type|
            Scale::Types.type_convert(type, specs["default"])
          end
        end
        .transform_values do |chain_types|
          specs["default"].merge(chain_types)
        end

      specs.merge(chain_specs)
    end

    def load_chain_spec_types(file)
      json_string = File.open(file).read
      types = JSON.parse(json_string)["types"]

      types.transform_values! do |type|
        if type.class != ::String
          Scale::Types.constantize(type)
        else
          Scale::Types.type_convert(type, types)
        end
      end
      types
    end

  end

  # TODO: == implement

  class Bytes
    attr_reader :data, :bytes
    attr_reader :offset

    def initialize(data)
      if (data.class == Array) && data.is_byte_array?
        @bytes = data
      elsif (data.class == String) && data.start_with?("0x") && (data.length % 2 == 0)
        arr = data[2..].scan(/../).map(&:hex)
        @bytes = arr
      else
        raise "Provided data is not valid"
      end

      @data = data
      @offset = 0
    end

    def reset_offset
      @offset = 0
    end

    def get_next_bytes(length)
      result = @bytes[@offset...@offset + length]
      if result.length < length
        str = @data[(2 + @offset * 2)..]
        str = str.length > 40 ? (str[0...40]).to_s + "..." : str
        raise "No enough data: #{str}, expect length: #{length}, but #{result.length}" 
      end
      @offset += length
      result
    end

    def get_remaining_bytes
      @bytes[offset..]
      @offset = @bytes.length
      result
    end

    def to_hex_string
      @bytes.bytes_to_hex
    end

    def to_bin_string
      @bytes.bytes_to_bin
    end

    def ==(other)
      bytes == other.bytes && offset == other.offset
    end
  end

  class TypesLoader
    def self.load(filename)
      path = File.join File.dirname(__FILE__), "types", filename
      content = File.open(path).read
      result = JSON.parse content

      types = result["default"]
      types.each do |name, body|
        if body.class == String
          target_type = "Scale::Types::#{body}"
          klass = Class.new(target_type.constantize) do
          end
        elsif body.class == Hash
          if body["type"] == "struct"
            struct_params = {}
            body["type_mapping"].each do |mapping|
              struct_params[mapping[0].to_sym] = mapping[1]
            end
            klass = Class.new do
            end
            klass.send(:include, Scale::Types::Struct)
            klass.send(:items, struct_params)
            Scale::Types.const_set name, klass
          elsif body["type"] = "enum"
            klass = Class.new do
            end
            klass.send(:include, Scale::Types::Enum)
            if body["type_mapping"]
              struct_params = {}
              body["type_mapping"].each do |mapping|
                struct_params[mapping[0].to_sym] = mapping[1]
              end
              klass.send(:items, struct_params)
            else
              klass.send(:values, body["value_list"])
            end
            Scale::Types.const_set name, klass
          end
        end
      end
    end
  end

  module Types
    
    def self.list(chain_spec = "default")
      TypeRegistry.instance.types[chain_spec].keys
    end

    def self.get(type_name, chain_spec = "default")
      TypeRegistry.instance.get(type_name, chain_spec)
    end

    def self.constantize(type)
      if type.class == ::String
        type_of(type.strip)
      else
        if type["type"] == "enum" && type.has_key?("type_mapping")
          type_of("Enum", type["type_mapping"].to_h)
        elsif type["type"] == "enum" && type.has_key?("value_list")
          type_of("Enum", type["value_list"])
        elsif type["type"] == "struct"
          type_of("Struct", type["type_mapping"].to_h)
        elsif type["type"] == "set"
          type_of("Set", type["value_list"])
        end
      end
    end

    def self.type_convert(type, types)
      return type if type.class != ::String

      if type =~ /\[u\d+; \d+\]/
        byte_length = type.scan(/\[u\d+; (\d+)\]/).first.first
        "VecU8Length#{byte_length}"
      elsif types.has_key?(type) && types[type] != type
        type_convert(types[type], types)
      else
        # u32 => U32
        type.gsub(/(u)(\d+)/, 'U\2')
      end
    end

    def self.type_of(type_string, values = nil)
      if type_string.end_with?(">")
        type_strs = type_string.scan(/^([^<]*)<(.+)>$/).first
        type_str = type_strs.first
        inner_type_str = type_strs.last

        if type_str == "Vec" || type_str == "Option"
          klass = Class.new do
            include Scale::Types.type_of(type_str)
            inner_type inner_type_str
          end
          name = "#{type_str}_Of_#{inner_type_str.camelize}_#{klass.object_id}"
          Scale::Types.const_set fix(name), klass
        else
          raise "#{type_str} not support inner type"
        end
      elsif type_string.start_with?("(") && type_string.end_with?(")") # tuple
        # TODO: add nested tuple support
        types_with_inner_type = type_string[1...-1].scan(/([A-Za-z]+<[^>]*>)/).first

        types_with_inner_type&.each do |type_str|
          new_type_str = type_str.tr(",", ";")
          type_string = type_string.gsub(type_str, new_type_str)
        end

        type_strs = type_string[1...-1].split(",").map do |type_str|
          type_str.strip.tr(";", ",")
        end

        klass = Class.new do
          include Scale::Types::Tuple
          inner_types *type_strs
        end
        name = "Tuple_Of_#{type_strs.map(&:camelize).join("_")}_#{klass.object_id}"
        Scale::Types.const_set fix(name), klass
      else
        if type_string == "Enum"
          # TODO: combine values to items
          klass = Class.new do
            include Scale::Types::Enum
            if values.class == ::Hash
              items values
            else
              values(*values)
            end
          end
          name = values.class == ::Hash ? values.values.map(&:camelize).join("_") : values.map(&:camelize).join("_")
          name = "Enum_Of_#{name}_#{klass.object_id}"
          Scale::Types.const_set fix(name), klass
        elsif type_string == "Struct"
          klass = Class.new do
            include Scale::Types::Struct
            items values
          end
          name = "Struct_Of_#{values.values.map(&:camelize).join("_")}_#{klass.object_id}"
          Scale::Types.const_set fix(name), klass
        elsif type_string == "Set"
          klass = Class.new do
            include Scale::Types::Set
            items values, 1
          end
          name = "Set_Of#{values.keys.map(&:camelize).join("_")}_#{klass.object_id}"
          Scale::Types.const_set fix(name), klass
        else
          type_name = (type_string.start_with?("Scale::Types::") ? type_string : "Scale::Types::#{type_string}")
          begin
            type_name.constantize
          rescue NameError => e
            puts "#{type_string} is not defined"
          end
        end
      end
    end
  end

end

def fix(name)
  name
    .gsub("<", "˂").gsub(">", "˃")
    .gsub("(", "⁽").gsub(")", "⁾")
    .gsub(" ", "").gsub(",", "‚")
end

def adjust(type)
  type = type.gsub("T::", "")
    .gsub("<T>", "")
    .gsub("<T as Trait>::", "")
    .delete("\n")
    .gsub("EventRecord<Event, Hash>", "EventRecord")
  return "Null" if type == "()"
  return "String" if type == "Vec<u8>"
  return "Address" if type == "<Lookup as StaticLookup>::Source"
  return "Vec<Address>" if type == "Vec<<Lookup as StaticLookup>::Source>"
  return "CompactBalance" if type == "<Balance as HasCompact>::Type"
  return "CompactBlockNumber" if type == "<BlockNumber as HasCompact>::Type"
  return "CompactBalance" if type == "<Balance as HasCompact>::Type"
  return "CompactMoment" if type == "<Moment as HasCompact>::Type"
  return "InherentOfflineReport" if type == "<InherentOfflineReport as InherentOfflineReport>::Inherent"
  type
end
