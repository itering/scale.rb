module Scale
  module Types

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
        String.new bytes.pack('C*').force_encoding('utf-8')
      end
    end

    class H256
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(32)
        H256.new(bytes.bytes_to_hex)
      end
    end

    class H512
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(64)
        H512.new(bytes.bytes_to_hex)
      end
    end

    class AccountId < H256
    end

    class Balance < U128
    end

    class BalanceOf < Balance
    end

    class BlockNumber < U32
    end

    class Era
      include SingleValue
      def self.decode(scale_bytes)
        byte = scale_bytes.get_next_bytes(1).bytes_to_hex
        puts byte.class
        if byte == '0x00'
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
        proposal: 'Scale::Types::Hex',
        registredBy: 'Scale::Types::AccountId',
        deposit: 'Scale::Types::OptionU32', # 选修课数量, nil表示还没有选
        int_or_bool: 'Scale::Types::IntOrBool'
      )
    end

    class StorageHasher
      include Enum
      values 'Blake2_128', 'Blake2_256', 'Twox128', 'Twox256', 'Twox128Concat'
    end
  end
end
