require "scale/version"

require "substrate_common"
require "json"
require "active_support"
require "active_support/core_ext/string"
require "singleton"

require "scale/base"
require "scale/types"
require "scale/block"

require "metadata/metadata"
require "metadata/metadata_v0"
require "metadata/metadata_v1"
require "metadata/metadata_v2"
require "metadata/metadata_v3"
require "metadata/metadata_v4"
require "metadata/metadata_v5"
require "metadata/metadata_v6"
require "metadata/metadata_v7"
require "metadata/metadata_v8"
require "metadata/metadata_v9"
require "metadata/metadata_v10"
require "metadata/metadata_v11"

module Scale
  class Error < StandardError; end

  class TypeRegistry
    include Singleton
    attr_accessor :types, :versioning
    attr_accessor :spec_version, :metadata
    attr_accessor :custom_types

    def load(spec_name = nil, custom_types = nil)
      default_types, _ = load_chain_spec_types("default")

      if spec_name.nil? || spec_name == "default"
        @types = default_types
      else
        spec_types, @versioning = load_chain_spec_types(spec_name)
        @types = default_types.merge(spec_types)
      end

      @custom_types = custom_types.stringify_keys if custom_types.nil? && custom_types.class.name == "Hash"
      true
    end

    def get(type_name)
      raise "Types not loaded" if @types.nil?

      all_types = {}.merge(@types)

      if @spec_version && @versioning
        @versioning.each do |item|
          if @spec_version >= item["runtime_range"][0] && @spec_version <= (item["runtime_range"][1] || 1073741823)
            all_types.merge!(item["types"])
          end
        end
      end

      all_types.merge!(@custom_types) if @custom_types

      type = type_traverse(type_name, all_types)

      Scale::Types.constantize(type)
    end

    def load_chain_spec_types(spec_name)
      file = File.join File.expand_path("../..", __FILE__), "lib", "type_registry", "#{spec_name}.json"
      json_string = File.open(file).read
      json = JSON.parse(json_string)

      runtime_id = json["runtime_id"]

      [json["types"], json["versioning"]]
    end

    def type_traverse(type, types)
      if types.has_key?(type)
        type_traverse(types[type], types)
      else
        if type.class == ::String
          rename(type)
        else
          type
        end
      end
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
    rescue RangeError => ex
      puts "length: #{length}"
      puts ex.message
      puts ex.backtrace
    end

    def get_remaining_bytes
      @bytes[offset..]
    end

    def to_hex_string
      @bytes.bytes_to_hex
    end

    def to_bin_string
      @bytes.bytes_to_bin
    end

    def to_ascii 
      @bytes[0...offset].pack("C*") + "<================================>" + @bytes[offset..].pack("C*")
    end

    def ==(other)
      bytes == other.bytes && offset == other.offset
    end

    def to_s
      green(@bytes[0...offset].bytes_to_hex) + yellow(@bytes[offset..].bytes_to_hex[2..])
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
    def self.list
      TypeRegistry.instance.types
    end

    def self.get(type_name)
      TypeRegistry.instance.get(type_name)
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
          raise "#{type_str} not support inner type: #{type_string}"
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
          name = "Set_Of_#{values.keys.map(&:camelize).join("_")}_#{klass.object_id}"
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
    .gsub(":", "։")
end

def rename(type)
  type = type.gsub("T::", "")
    .gsub("<T>", "")
    .gsub("<T as Trait>::", "")
    .delete("\n")
    .gsub("EventRecord<Event, Hash>", "EventRecord")
    .gsub(/(u)(\d+)/, 'U\2')
  return "Bool" if type == "bool"
  return "Null" if type == "()"
  return "String" if type == "Vec<u8>"
  return "Compact" if type == "Compact<u32>" || type == "Compact<U32>"
  return "Address" if type == "<Lookup as StaticLookup>::Source"
  return "Vec<Address>" if type == "Vec<<Lookup as StaticLookup>::Source>"
  return "Compact" if type == "<Balance as HasCompact>::Type"
  return "Compact" if type == "<BlockNumber as HasCompact>::Type"
  return "Compact" if type == "Compact<Balance>"
  return "CompactMoment" if type == "<Moment as HasCompact>::Type"
  return "CompactMoment" if type == "Compact<Moment>"
  return "InherentOfflineReport" if type == "<InherentOfflineReport as InherentOfflineReport>::Inherent"
  return "AccountData" if type == "AccountData<Balance>"

  if type =~ /\[U\d+; \d+\]/
    byte_length = type.scan(/\[U\d+; (\d+)\]/).first.first
    return "VecU8Length#{byte_length}"
  end

  type
end

def green(text)
  "\033[32m#{text}\033[0m"
end

def yellow(text)
  "\033[33m#{text}\033[0m"
end

# https://www.ruby-forum.com/t/question-about-hex-signed-int/125510/4
# machine bit length:
#   machine_byte_length = ['foo'].pack('p').size
#   machine_bit_length = machine_byte_length * 8
class Integer
  def to_signed(bit_length)
    unsigned_mid = 2 ** (bit_length - 1)
    unsigned_ceiling = 2 ** bit_length
    (self >= unsigned_mid) ? self - unsigned_ceiling : self
  end

  def to_unsigned(bit_length)
    unsigned_mid = 2 ** (bit_length - 1)
    unsigned_ceiling = 2 ** bit_length 
    if self >= unsigned_mid || self <= -unsigned_mid
      raise "out of scope"
    end
    return unsigned_ceiling + self if self < 0
    self
  end
end

class ::Hash
  # via https://stackoverflow.com/a/25835016/2257038
  def stringify_keys
    h = self.map do |k,v|
      v_str = if v.instance_of? Hash
                v.stringify_keys
              else
                v
              end

      [k.to_s, v_str]
    end
    Hash[h]
  end
end
