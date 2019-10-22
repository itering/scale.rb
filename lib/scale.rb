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
      @bytes.to_hex_string
    end

    def to_bin_string
      @bytes.to_bin_string
    end

    def ==(another_object)
      self.bytes == another_object.bytes && self.offset == another_object.offset
    end
  end

end
