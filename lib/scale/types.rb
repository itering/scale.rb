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

    class U8
      include FixedWidthUInt
      BYTES_LENGTH = 1
    end

    class U16
      include FixedWidthUInt
      BYTES_LENGTH = 2
    end

    class U32
      include FixedWidthUInt
      BYTES_LENGTH = 4
    end

    class U64
      include FixedWidthUInt
      BYTES_LENGTH = 8
    end

    class U128
      include FixedWidthUInt
      BYTES_LENGTH = 16
    end

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

    class Bytes
      include SingleValue

      def self.decode(scale_bytes)
        length = Scale::Types::Compact.decode(scale_bytes).value
        bytes = scale_bytes.get_next_bytes(length)
          # [67, 97, 102, 195, 169].pack('C*').force_encoding('utf-8')
          # => "Café"
          str = bytes.pack("C*").force_encoding("utf-8")
          if str.valid_encoding?
            Bytes.new str
          else
            Bytes.new bytes.bytes_to_hex
          end
      end

      def encode
        if self.value.start_with?("0x")
          length = Compact.new((self.value.length - 2)/2).encode
          "#{length}#{self.value[2..]}"
        else
          bytes = self.value.unpack("C*")
          hex_string = bytes.bytes_to_hex[2..]
          length = Compact.new(bytes.length).encode
          "#{length}#{hex_string}"
        end
      end
    end

    class Hex
      include SingleValue

      def self.decode(scale_bytes)
        length = Scale::Types::Compact.decode(scale_bytes).value
        hex_string = scale_bytes.get_next_bytes(length).bytes_to_hex
        Hex.new(hex_string)
      end
    end

    class String
      include SingleValue
      def self.decode(scale_bytes)
        length = Scale::Types::Compact.decode(scale_bytes).value
        bytes = scale_bytes.get_next_bytes(length)
        String.new bytes.pack("C*").force_encoding("utf-8")
      end
    end

    class H160
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(20)
        H160.new(bytes.bytes_to_hex)
      end

      def encode
        raise "Format error" if not self.value.start_with?("0x") || self.value.length != 42
        ScaleBytes.new self.value
      end
    end

    class H256
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(32)
        H256.new(bytes.bytes_to_hex)
      end

      def encode
        raise "Format error" if not self.value.start_with?("0x") || self.value.length != 66
        ScaleBytes.new self.value
      end
    end

    class H512
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(64)
        H512.new(bytes.bytes_to_hex)
      end

      def encode
        raise "Format error" if not self.value.start_with?("0x") || self.value.length != 130
        ScaleBytes.new self.value
      end
    end

    class AccountId < H256; end

    class Balance < U128; end

    class BalanceOf < Balance; end

    class BlockNumber < U32; end

    class AccountIndex < U32; end

    class Era
      include SingleValue
      def self.decode(scale_bytes)
        byte = scale_bytes.get_next_bytes(1).bytes_to_hex
        if byte == "0x00"
          Era.new byte
        else
          Era.new byte + scale_bytes.get_next_bytes(1).bytes_to_hex()[2..]
        end
      end
    end

    class EraIndex < U32; end

    class Moment < U64; end

    class CompactMoment
      include SingleValue
      def self.decode(scale_bytes)
        value = Compact.decode(scale_bytes).value
        if value > 10000000000
          value = value / 1000
        end

        CompactMoment.new Time.at(seconds_since_epoch_integer).to_datetime
      end
    end

    class ProposalPreimage
      include Struct
      items(
        proposal: "Hex",
        registredBy: "AccountId",
        deposit: "BalanceOf",
        blockNumber: "BlockNumber"
      )
    end

    class StorageHasher
      include Enum
      values "Blake2_128", "Blake2_256", "Twox128", "Twox256", "Twox128Concat"
    end

    class RewardDestination
      include Enum
      values "Staked", "Stash", "Controller"
    end

    class WithdrawReasons
      include Set
      values "TransactionPayment" => 1, \
        "Transfer" => 2, \
        "Reserve" => 4, \
        "Fee" => 8, \
        "Tip" => 16
    end

    class ReferendumIndex < U32; end

    class PropIndex < U32; end

    class Vote < U32; end

    class SessionKey < H256; end

    class SessionIndex < U32; end

    class ParaId < U32; end

    class KeyValue
      include Struct
      items key: "Vec<U8>", value: "Vec<U8>"
    end

    class NewAccountOutcome < Compact; end

    class Data
      include Enum
      items(
        None: "Null",
        Raw: "Bytes",
        BlakeTwo256: "H256",
        Sha256: "H256",
        Keccak256: "H256",
        ShaThree256: "H256"
      )

      def self.decode(scale_bytes)

      end
    end


    
  end
end
