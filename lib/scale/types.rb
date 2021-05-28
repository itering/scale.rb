module Scale
  module Types

    class Bool
      include SingleValue
      BYTES_LENGTH = 1

      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        bytes = scale_bytes.get_next_bytes(self::BYTES_LENGTH)
        if bytes == [0]
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new(false)
        elsif bytes == [1]
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new(true)
        else
          raise "Bad data"
        end
      end

      def encode
        value === true ? "01" : "00"
      end
    end

    class OptionBool
      include SingleValue
      def self.decode(scale_bytes)
        byte = scale_bytes.get_next_bytes(1)[0]
        value = if byte == 0x00
                  nil
                elsif byte == 0x01
                  true
                elsif byte == 0x02
                  false
                else
                  raise BadDataError.new("Bad scale data for OptionBool #{byte.to_s(16)}")
                end
        new(value)
      end

      def encode
        if value.nil?
          "00"
        elsif value === true
          "01"
        elsif value === false
          "02"
        else
          raise WrongValueError.new("OptionBool can not have value other than `nil`, `true`, `false`")
        end
      end
    end

    class U8
      include FixedWidthUInt
      BYTE_LENGTH = 1
    end

    class U16
      include FixedWidthUInt
      BYTE_LENGTH = 2
    end

    class U32
      include FixedWidthUInt
      BYTE_LENGTH = 4
    end

    class U64
      include FixedWidthUInt
      BYTE_LENGTH = 8
    end

    class U128
      include FixedWidthUInt
      BYTE_LENGTH = 16
    end

    class U256
      include FixedWidthUInt
      BYTE_LENGTH = 32
    end

    class U512
      include FixedWidthUInt
      BYTE_LENGTH = 64
    end

    class I8
      include FixedWidthInt
      BYTE_LENGTH = 1
    end

    class I16
      include FixedWidthInt
      BYTE_LENGTH = 2
    end

    class I32
      include FixedWidthInt
      BYTE_LENGTH = 4
    end

    class I64
      include FixedWidthInt
      BYTE_LENGTH = 8
    end

    class I128
      include FixedWidthInt
      BYTE_LENGTH = 16
    end

    class Compact
      include SingleValue

      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        first_byte = scale_bytes.get_next_bytes(1)[0]
        first_byte_in_bin = first_byte.to_s(2).rjust(8, "0")

        mode = first_byte_in_bin[6..7]
        value =
          if mode == "00"
            first_byte >> 2
          elsif mode == "01"
            second_byte = scale_bytes.get_next_bytes(1)[0]
            [first_byte, second_byte]
              .reverse
              .map { |b| b.to_s(16).rjust(2, "0") }
              .join
              .to_i(16) >> 2
          elsif mode == "10"
            remaining_bytes = scale_bytes.get_next_bytes(3)
            ([first_byte] + remaining_bytes)
              .reverse
              .map { |b| b.to_s(16).rjust(2, "0") }
              .join
              .to_i(16) >> 2
            # or like this:
            # ['02093d00'].pack('H*').unpack('l').first / 4
          elsif mode == "11"
            remaining_length = 4 + (first_byte >> 2)
            remaining_bytes = scale_bytes.get_next_bytes(remaining_length)
            remaining_bytes
              .reverse
              .map { |b| b.to_s(16).rjust(2, "0") }
              .join
              .to_i(16)
          end

        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new(value)
      end

      def encode
        if (value >= 0) && (value <= 63)
          (value << 2).to_s(16).rjust(2, "0")
        elsif (value > 63) && (value <= (2**14 - 1))
          ((value << 2) + 1).to_s(16).rjust(4, "0").scan(/.{2}/).reverse.join
        elsif (value > (2**14 - 1)) && (value <= (2**30 - 1))
          ((value << 2) + 2).to_s(16).rjust(8, "0").scan(/.{2}/).reverse.join
        elsif value > (2**30 - 1)
          value_in_hex = value.to_s(16)
          length = if value_in_hex.length % 2 == 1
            value_in_hex.length + 1
          else
            value_in_hex.length
          end

          hex = value_in_hex.rjust(length, "0").scan(/.{2}/).reverse.join
          (((length/2 - 4) << 2) + 3).to_s(16).rjust(2, "0") + hex
        end
      end
    end

    class Bytes
      include SingleValue

      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        length = Scale::Types::Compact.decode(scale_bytes).value
        bytes = scale_bytes.get_next_bytes(length)

        # [67, 97, 102, 195, 169].pack('C*').force_encoding('utf-8')
        # => "Café"
        str = bytes.pack("C*").force_encoding("utf-8")
        if str.valid_encoding?
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new str
        else
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new bytes.bytes_to_hex
        end
      end

      def encode
        if value.start_with?("0x")
          length = Compact.new((value.length - 2)/2).encode
          "#{length}#{value[2..]}"
        else
          bytes = value.unpack("C*")
          hex_string = bytes.bytes_to_hex[2..]
          length = Compact.new(bytes.length).encode
          "#{length}#{hex_string}"
        end
      end
    end

    class Hex
      include SingleValue

      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        length = Scale::Types::Compact.decode(scale_bytes).value
        hex_string = scale_bytes.get_next_bytes(length).bytes_to_hex
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new(hex_string)
      end

      def encode
        length = Compact.new((value.length - 2)/2).encode
        "#{length}#{value[2..]}"
      end
    end

    class String
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        length = Scale::Types::Compact.decode(scale_bytes).value
        bytes = scale_bytes.get_next_bytes(length)
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new bytes.pack("C*").force_encoding("utf-8")
      end
    end

    class H160
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        bytes = scale_bytes.get_next_bytes(20)
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new(bytes.bytes_to_hex)
      end

      def encode
        raise "Format error" unless value.start_with?("0x") || value.length != 42
        value[2..]
      end
    end

    class H256
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        bytes = scale_bytes.get_next_bytes(32)
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new(bytes.bytes_to_hex)
      end

      def encode
        raise "Format error" unless value.start_with?("0x") || value.length != 66
        value[2..]
      end
    end

    class H512
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        bytes = scale_bytes.get_next_bytes(64)
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new(bytes.bytes_to_hex)
      end

      def encode
        raise "Format error" unless value.start_with?("0x") || value.length != 130
        value[2..]
      end
    end

    class GenericAddress
      include SingleValue

      # https://github.com/paritytech/substrate/wiki/External-Address-Format-(SS58)
      # base58encode ( concat ( <address-type>, <address>, <checksum> ) )
      #                                         ^^^^^^^^^
      # the <address> is 32 byte account id or 1, 2, 4, 8 byte account index
      # scale_bytes: account length byte  + <address>'s bytes
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        account_length = scale_bytes.get_next_bytes(1).first

        if account_length == 0xff # 32 bytes address(Public key)
          account_id = scale_bytes.get_next_bytes(32).bytes_to_hex
          account_length = [account_length].bytes_to_hex

          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new({
            account_id: account_id,
            account_length: account_length
          })
        else
          account_index =
            if account_length == 0xfc # 2 bytes address(account index)
              scale_bytes.get_next_bytes(2).bytes_to_hex
            elsif account_length == 0xfd # 4 bytes address(account index)
              scale_bytes.get_next_bytes(4).bytes_to_hex
            elsif account_length == 0xfe # 8 bytes address(account index)
              scale_bytes.get_next_bytes(8).bytes_to_hex
            else
              [account_length].bytes_to_hex
            end
          # TODO: add account_idx 
          account_length = [account_length].bytes_to_hex

          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new({
            account_index: account_index,
            account_length: account_length
          })
        end
      end

      def encode
        if self.value[:account_id]
          "#{self.value[:account_length][2..]}#{self.value[:account_id][2..]}"
        else
          "#{self.value[:account_length][2..]}#{self.value[:account_index][2..]}"
        end
      end
    end

    class Address < GenericAddress; end

    class RawAddress < GenericAddress; end

    class AccountIdAddress < GenericAddress
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        result = new({
          account_id: AccountId.decode(scale_bytes).value,
          account_length: "0xff"
        })

        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        result
      end

      def encode
        "ff#{self.value[:account_id][2..]}"
      end
    end

    class GenericMultiAddress
      include Enum
      items(
        Id: "AccountId",
        Index: "Compact",
        Raw: "Hex",
        Address32: "H256",
        Address20: "H160"
      )
    end

    class AccountId < H256; end

    class Balance < U128; end

    class BalanceOf < Balance; end

    class BlockNumber < U32; end

    class AccountIndex < U32; end

    class Era
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        byte = scale_bytes.get_next_bytes(1).bytes_to_hex
        result = if byte == "0x00"
          new byte
        else
          new byte + scale_bytes.get_next_bytes(1).bytes_to_hex()[2..]
        end
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        result
      end
    end

    class EraIndex < U32; end

    class Moment < U64; end

    class CompactMoment
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        value = Compact.decode(scale_bytes).value
        if value > 10000000000
          value /= 1000
        end

        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new Time.at(value).strftime("%F %T")
      end
    end

    class ProposalPreimage
      include Struct
      items(
        proposal: "Hex",
        registred_by: "AccountId",
        deposit: "BalanceOf",
        blockNumber: "BlockNumber"
      )
    end

    class RewardDestination
      include Enum
      values "Staked", "Stash", "Controller"
    end

    class WithdrawReasons
      include Set
      items(
        {
          TransactionPayment: 1,
          Transfer: 2,
          Reserve: 4,
          Fee: 8,
          Tip: 16
        }, 1
      )
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

    class StakingLedger
      include Struct
      items(
        stash: "AccountId",
        total: "Compact",
        active: "Compact",
        unlocking: "Vec<UnlockChunk>"
      )
    end

    class UnlockChunk
      include Struct
      items(
        value: "Compact",
        era: "Compact"
      )
    end

    class Exposure
      include Struct
      items(
        total: "Compact",
        own: "Compact",
        others: "Vec<IndividualExposure>"
      )
    end

    class IndividualExposure
      include Struct
      items(
        who: "AccountId",
        value: "Compact"
      )
    end

    class BabeAuthorityWeight < U64; end

    class Points < U32; end

    class EraPoints
      include Struct
      items(
        total: "Points",
        individual: "Vec<Points>"
      )
    end

    class VoteThreshold
      include Enum
      values "SuperMajorityApprove", "SuperMajorityAgainst", "SimpleMajority"
    end

    class Null
      include SingleValue
      def self.decode(scale_bytes)
        new nil
      end

      def encode
        ""
      end
    end

    class InherentOfflineReport < Null; end

    class LockPeriods < U8; end

    class Hash < H256; end

    class VoteIndex < U32; end

    class ProposalIndex < U32; end

    class Permill < U32; end

    class Perbill < U32; end

    class ApprovalFlag < U32; end

    class SetIndex < U32; end

    class AuthorityId < AccountId; end

    class ValidatorId < AccountId; end

    class AuthorityWeight < U64; end

    class StoredPendingChange
      include Struct
      items(
        scheduled_at: "U32",
        forced: "U32"
      )
    end

    class ReportIdOf < Hash; end

    class StorageHasher
      include Enum
      values "Blake2_128", "Blake2_256", "Blake2_128Concat", "Twox128", "Twox256", "Twox64Concat", "Identity"
    end

    class VoterInfo
      include Struct
      items(
        last_active: "VoteIndex",
        last_win: "VoteIndex",
        pot: "Balance",
        stake: "Balance"
      )
    end

    class Gas < U64; end

    class CodeHash < Hash; end

    class PrefabWasmModule
      include Struct
      items(
        scheduleVersion: "Compact",
        initial: "Compact",
        maximum: "Compact",
        _reserved: "Option<Null>",
        code: "Bytes"
      )
    end

    class OpaqueNetworkState
      include Struct
      items(
        peerId: "OpaquePeerId",
        externalAddresses: "Vec<OpaqueMultiaddr>"
      )
    end

    class OpaquePeerId < Bytes; end

    class OpaqueMultiaddr < Bytes; end

    class SessionKeysSubstrate
      include Struct
      items(
        grandpa: "AccountId",
        babe: "AccountId",
        im_online: "AccountId"
      )
    end

    class LegacyKeys
      include Struct
      items(
        grandpa: "AccountId",
        babe: "AccountId"
      )
    end

    class EdgewareKeys
      include Struct
      items(
        grandpa: "AccountId"
      )
    end

    class QueuedKeys
      include Struct
      items(
        validator: "ValidatorId",
        keys: "Keys"
      )
    end

    class LegacyQueuedKeys
      include Struct
      items(
        validator: "ValidatorId",
        keys: "LegacyKeys"
      )
    end

    class EdgewareQueuedKeys
      include Struct
      items(
        validator: "ValidatorId",
        keys: "EdgewareKeys"
      )
    end

    class VecQueuedKeys
      include Vec
      inner_type "QueuedKeys"
    end

    class VecU8Length2
      include VecU8FixedLength
      BYTE_LENGTH = 2
    end

    class VecU8Length3
      include VecU8FixedLength
      BYTE_LENGTH = 3
    end

    class VecU8Length4
      include VecU8FixedLength
      BYTE_LENGTH = 4
    end

    class VecU8Length8
      include VecU8FixedLength
      BYTE_LENGTH = 8
    end

    class VecU8Length16
      include VecU8FixedLength
      BYTE_LENGTH = 16
    end

    class VecU8Length20
      include VecU8FixedLength
      BYTE_LENGTH = 20
    end

    class VecU8Length32
      include VecU8FixedLength
      BYTE_LENGTH = 32
    end

    class VecU8Length64
      include VecU8FixedLength
      BYTE_LENGTH = 64
    end

    class VecU8Length128
      include VecU8FixedLength
      BYTE_LENGTH = 128
    end

    class VecU8Length256
      include VecU8FixedLength
      BYTE_LENGTH = 256
    end

    class BalanceLock
      include Struct
      items(
        id: "VecU8Length8",
        amount: "Scale::Types::Balance",
        until: "U32",
        reasons: "Scale::Types::WithdrawReasons"
      )
    end

    class EthereumAddress
      include SingleValue

      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        bytes = scale_bytes.get_next_bytes(20)
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        new(bytes.bytes_to_hex)
      end

      def encode
        if value.start_with?("0x") && value.length == 42
          value[2..]
        else
          raise 'Value should start with "0x" and must be 20 bytes long'
        end
      end
    end

    class EcdsaSignature
      include SingleValue

      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        bytes = scale_bytes.get_next_bytes(65)
        new(bytes.bytes_to_hex)
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
      end

      def encode
        if value.start_with?("0x") && value.length == 132
          value[2..]
        else
          raise 'Value should start with "0x" and must be 65 bytes long'
        end
      end
    end

    class Bidder
      include Enum
      values "NewBidder", "ParaId"
    end

    class BlockAttestations
      include Struct
      items(
        receipt: "CandidateReceipt",
        valid: "Vec<AccountId>",
        invalid: "Vec<AccountId>"
      )
    end

    class IncludedBlocks
      include Struct
      items(
        actual_number: "BlockNumber",
        session: "SessionIndex",
        random_seed: "H256",
        active_parachains: "Vec<ParaId>",
        para_blocks: "Vec<Hash>"
      )
    end

    class HeadData < Bytes; end

    class Conviction
      include Enum
      values "None", "Locked1x", "Locked2x", "Locked3x", "Locked4x", "Locked5x", "Locked6x"
    end

    class EraRewards
      include Struct
      items(
        total: "U32",
        rewards: "Vec<U32>"
      )
    end

    class SlashJournalEntry
      include Struct
      items(
        who: "AccountId",
        amount: "Balance",
        ownSlash: "Balance"
      )
    end

    class UpwardMessage
      include Struct
      items(
        origin: "ParachainDispatchOrigin",
        data: "Bytes"
      )
    end

    class ParachainDispatchOrigin
      include Enum
      values "Signed", "Parachain"
    end

    class StoredState
      include Enum
      values "Live", "PendingPause", "Paused", "PendingResume"
    end

    class Votes
      include Struct
      items(
        index: "ProposalIndex",
        threshold: "MemberCount",
        ayes: "Vec<AccountId>",
        nays: "Vec<AccountId>"
      )
    end

    class WinningDataEntry
      include Struct
      items(
        account_id: "AccountId",
        para_id_of: "ParaIdOf",
        balance_of: "BalanceOf"
      )
    end

    class IdentityType < Bytes; end

    class VoteType
      include Enum
      values "Binary", "MultiOption"
    end

    class VoteOutcome
      include SingleValue
      def self.decode(scale_bytes)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        result = new(scale_bytes.get_next_bytes(32))
        
        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        result
      end
    end

    class Identity < Bytes; end

    class ProposalTitle < Bytes; end

    class ProposalContents < Bytes; end

    class ProposalStage
      include Enum
      values "PreVoting", "Voting", "Completed"
    end

    class ProposalCategory
      include Enum
      values "Signaling"
    end

    class VoteStage
      include Enum
      values "PreVoting", "Commit", "Voting", "Completed"
    end

    class TallyType
      include Enum
      values "OnePerson", "OneCoin"
    end

    class Attestation < Bytes; end

    class VecNextAuthority
      include Vec
      inner_type "NextAuthority"
    end

    class BoxProposal
      include SingleValue

      def self.decode(scale_bytes, metadata, chain_spec)
        puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        call_index = scale_bytes.get_next_bytes(2).bytes_to_hex[2..]
        call_module, call = metadata.value.call_index[call_index]

        call_args = call[:args].map do |arg|
          arg_obj = Scale::Types.get(arg[:type], chain_spec).decode(scale_bytes)
          {name: arg[:name], type: arg[:type], value: arg_obj.encode, value_raw: arg_obj.value}
        end

        puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
        self.new({
          call_index: call_index, 
          call_function: call[:name],
          call_module: call_module[:name],
          call_args: call_args
        })
      end

      def encode
        value[:call_index] +
        value[:call_args]
          .map {|call_arg| call_arg[:value]}
          .join("")
      end
    end

    class ValidatorPrefsLegacy
      include Struct
      items(
        unstake_threshold: "Compact",
        validator_payment: "Compact"
      )
    end

    class VecH512Length2
      include SingleValue

      def self.decode(scale_bytes)
      end

      def encode
        "0x" + self.value.map do |item|
          item[2..]
        end.join
      end
    end

    class GenericBlock
      include SingleValue

      def self.decode(scale_bytes)
      end

      def encode
      end
    end

  end
end
