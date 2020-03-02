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
require "metadata/metadata_v10"

module Scale
  class Error < StandardError; end
  # TODO: == implement

  class Bytes
    attr_reader :data, :bytes
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

      @data   = data
      @offset = 0
    end

    def reset_offset
      @offset = 0
    end

    def get_next_bytes(length)
      result = @bytes[@offset ... @offset + length]
      if result.length < length
        str = @data[(2 + @offset * 2)..]
        str = str.length > 40 ? (str[0...40]).to_s + "..." : str
        raise "No enough data: #{str}, expect length: #{length}, but #{result.length}" 
      end
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

def type_of(type_string, values: nil)
  if type_string.end_with?(">")
    type_strs = type_string.scan(/^([^<]*)<(.+)>$/).first
    type_str       = type_strs.first
    inner_type_str = type_strs.last

    if type_str == "Vec" || type_str == "Option"
      klass = Class.new do; end
      klass.send(:include, type_of(type_str))
      klass.send(:inner_type, inner_type_str)
      klass
    else
      raise "#{type_str} not support inner type"
    end
  else
    if type_string == 'Enum'
      klass = Class.new do; end
      klass.send(:include, Scale::Types::Enum)
      klass.send(:values, *values)
      klass
    else
      type_string = (type_string.start_with?("Scale::Types::") ? type_string : "Scale::Types::#{type_string}")
      type_string.constantize
    end
  end
end

def adjust(type)
  type = type.gsub("T::", "")
             .gsub("<T>", "")
             .gsub("<T as Trait>::", "")
             .gsub("\n", "")
             .gsub("EventRecord<Event, Hash>", "EventRecord")
  return "Null" if type == "()"
  return "String" if type == "Vec<u8>"
  return "Address" if type == '<Lookup as StaticLookup>::Source'
  return "Vec<Address>" if type == 'Vec<<Lookup as StaticLookup>::Source>'
  return "CompactBalance" if type == '<Balance as HasCompact>::Type'
  return 'CompactBlockNumber' if type == '<BlockNumber as HasCompact>::Type'
  return 'CompactBalance' if type == '<Balance as HasCompact>::Type'
  return 'CompactMoment' if type == '<Moment as HasCompact>::Type'
  return 'InherentOfflineReport' if type == '<InherentOfflineReport as InherentOfflineReport>::Inherent'
  return type
end
