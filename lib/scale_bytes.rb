module Scale
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
end
