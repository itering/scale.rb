module Scale
  module Types

    class Bool
      include SingleValue
      BYTES_LENGTH = 1

      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(self::BYTES_LENGTH)
        if bytes == [0]
          Bool.new(false)
        elsif bytes == [1]
          Bool.new(true)
        else
          raise "Bad data"
        end
      end

      def encode
        self.value === true ? "01" : "00"
      end
    end
  end
end
