require "scale/version"

require "substrate_common"

require "scale/base"
require "scale/fixed_width_integers"
require "scale/compact_integers"
require "scale/bool"
require "scale/types"
require "scale/options"
require "scale/enums"
require "scale/vectors"
require "scale/structs"

require "metadata/metadata"
require "metadata/metadata_v3"
require "metadata/metadata_v7"
require "metadata/metadata_v8"
require "metadata/metadata_v9"

module Scale
  class Error < StandardError; end
  # TODO: == implement

  class Bytes
    attr_reader :bytes
    attr_reader :offset

    def initialize(data)
      if data.class == Array and data.is_byte_array?
        @bytes = data
      elsif data.class == String and data.start_with?('0x') and data.length % 2 == 0
        arr = data[2..].scan(/../).map(&:hex)
        @bytes = arr
      else
        raise "Provided data is not valid"
      end

      @offset = 0
    end

    def reset_offset
      @offset = 0
    end

    def get_next_bytes(length)
      result = @bytes[@offset ... @offset + length]
      raise "No enough data: #{result.to_s}, expect length: #{length}, but #{result.length}" if result.length < length
      @offset = @offset + length
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

    def ==(another_object)
      self.bytes == another_object.bytes && self.offset == another_object.offset
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
          target_type  = "Scale::Types::#{body}"
          klass = Class.new(target_type.constantize) do
          end
        elsif body.class == Hash
          if body["type"] == "struct"
            struct_params = {}
            body['type_mapping'].each do |mapping|
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
              body['type_mapping'].each do |mapping|
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

end

def type(type_string, values: nil)
  klass = Class.new do; end
  if type_string == 'Enum'
    klass.send(:include, Scale::Types::Enum)
    klass.send(:values, *values)
  elsif type_string.end_with?(">")
    splits = type_string.split("<")
    if splits.first == "Vec"
      inner_type = splits.last.split(">").first
      klass.send(:include, Scale::Types::Vector)
      klass.send(:inner_type, inner_type)
    end
  end

  return klass
end
