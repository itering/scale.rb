module Scale
  module Types

    class Compact
      include SingleValue

      def self.decode(scale_bytes)
        first_byte = scale_bytes.get_next_bytes(1)[0]
        first_byte_in_bin = first_byte.to_s(2).rjust(8, '0')

        mode = first_byte_in_bin[6..7]
        value = 
          if mode == '00'
            first_byte >> 2
          elsif mode == '01'
            second_byte = scale_bytes.get_next_bytes(1)[0]
            [first_byte, second_byte]
              .reverse
              .map { |b| b.to_s(16).rjust(2, '0') }
              .join
              .to_i(16) >> 2
          elsif mode == '10'
            remaining_bytes = scale_bytes.get_next_bytes(3)
            ([first_byte] + remaining_bytes)
              .reverse
              .map { |b| b.to_s(16).rjust(2, '0') }
              .join
              .to_i(16) >> 2
            # or like this:
            # ['02093d00'].pack('H*').unpack('l').first / 4
          elsif mode == '11'
            remaining_length = 4 + (first_byte >> 2)
            remaining_bytes = scale_bytes.get_next_bytes(remaining_length)
            remaining_bytes
              .reverse
              .map { |b| b.to_s(16).rjust(2, '0') }
              .join
              .to_i(16)
          end

        Compact.new(value)
      end

      def encode
        if self.value >= 0 and self.value <= 63
          (value << 2).to_s(16).rjust(2, '0')
        elsif self.value > 63 and self.value <= (2**14 - 1)
          ((value << 2) + 1).to_s(16).rjust(4, '0').scan(/.{2}/).reverse.join
        elsif self.value > (2**14 - 1) and self.value <= (2**30 - 1)
          ((value << 2) + 2).to_s(16).rjust(8, '0').scan(/.{2}/).reverse.join
        elsif self.value > (2**30 - 1)
          value_in_hex = self.value.to_s(16)
          length = if value_in_hex.length % 2 == 1
            value_in_hex.length + 1
          else
            value_in_hex.length
          end

          hex = value_in_hex.rjust(length, '0').scan(/.{2}/).reverse.join
          (((length/2 - 4) << 2) + 3).to_s(16).rjust(2, '0') + hex
        end
      end
    end

  end
end
