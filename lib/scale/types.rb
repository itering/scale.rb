module Scale
  module Types

    class Hex
      include SingleValue

      def self.decode(scale_bytes)
        length = Scale::Types::Compact.decode(scale_bytes).value
        hex_string = scale_bytes.get_next_bytes(length).to_hex_string
        Hex.new(hex_string)
      end
    end

    class String
      include SingleValue
      def self.decode(scale_bytes)
        length = Scale::Types::Compact.decode(scale_bytes).value
        bytes = scale_bytes.get_next_bytes(length)
        String.new bytes.pack('C*').force_encoding('utf-8')
      end
    end

    class H256
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(32)
        H256.new(bytes.to_hex_string)
      end
    end

    class H512
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(64)
        H512.new(bytes.to_hex_string)
      end
    end

  end
end
