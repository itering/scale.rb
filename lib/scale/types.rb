module Scale
  module Bytes

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
