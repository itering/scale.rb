module Scale
  module Types
    
    class TrieNode
      include SingleValue
      EMPTY = 0
      NIBBLE_PER_BYTE = 2
      BITMAP_LENGTH = 2
      NIBBLE_LENGTH = 16
      NIBBLE_SIZE_BOUND = 65535

      def self.decode(scale_bytes)
        first = scale_bytes.get_next_bytes(1).first
        if first == EMPTY
          TrieNode.new({})
        else
          v = first & (0b11 << 6)
          decode_size = -> {
            result = first & 255 >> 2
            return result if result < 63
            result -= 1
            while result <= NIBBLE_SIZE_BOUND
              n = scale_bytes.get_next_bytes(1).first
              return (result + n + 1) if n < 255 
              result += 255
            end
            return NIBBLE_SIZE_BOUND
          }

          if v == 0b01 << 6 # leaf
            nibble_count = decode_size.call
            # if nibble_count is odd, the half of first byte of partial is 0
            padding = (nibble_count % NIBBLE_PER_BYTE) != 0 
            first_byte_of_partial = scale_bytes.bytes[scale_bytes.offset]
            if padding && (first_byte_of_partial & 0xf0) != 0
              raise "bad format"
            end

            ### partial decoding
            partial_bytes = scale_bytes.get_next_bytes((nibble_count + (NIBBLE_PER_BYTE - 1)) / NIBBLE_PER_BYTE)

            ### value
            count = Compact.decode(scale_bytes).value
            value_bytes = scale_bytes.get_next_bytes(count)

            return TrieNode.new({
              node_type: "leaf",
              partial: {
                hex: partial_bytes.bytes_to_hex, 
                padding: padding
              },
              value: value_bytes.bytes_to_hex
            })
          elsif v == 0b10 << 6 || v == 0b11 << 6 # branch without mask || branch with mask
            nibble_count = decode_size.call

            ### check that the padding is valid (if any)
            # if nibble_count is odd, the half of first byte of partial is 0
            padding = nibble_count % NIBBLE_PER_BYTE != 0
            first_byte_of_partial = scale_bytes.bytes[scale_bytes.offset]
            if padding && (first_byte_of_partial & 0xf0) != 0 
              raise "bad format"
            end

            ### partial decoding
            partial_bytes = scale_bytes.get_next_bytes((nibble_count + (NIBBLE_PER_BYTE - 1)) / NIBBLE_PER_BYTE)

            ### value decoding
            if v == 0b11 << 6 # has value
              count = Compact.decode(scale_bytes).value
              value_bytes = scale_bytes.get_next_bytes(count)
            end

            ### children decoding
            children = []
            bitmap = U16.decode(scale_bytes).value
            NIBBLE_LENGTH.times do |i|
              has_child = (bitmap & (1 << i)) != 0
              children[i] = nil
              if has_child
                count = Compact.decode(scale_bytes).value
                if count == 32
                  hash = H256.decode(scale_bytes).value
                  children[i] = hash
                else
                  inline = scale_bytes.get_next_bytes count
                  children[i] = inline.bytes_to_hex
                end
              end
            end
            # debug
            # children.each_with_index do |child, i|
            #   if child.nil?
            #     puts "#{i}: NULL" 
            #   else
            #     puts "#{i}: #{child}"
            #   end
            # end

            result = TrieNode.new({
              node_type: "branch",
              partial: {
                hex: partial_bytes.bytes_to_hex, 
                padding: padding
              },
              children: children
            })

            result[:value] = value_bytes.bytes_to_hex if value_bytes

            return result
          else
            puts "Not support"
          end

        end
      end
    end

  end
end
