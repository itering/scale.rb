module Scale
  module Types

    class Extrinsic
      include Base
      # attr_accessor :address, :signature, :nonce, :era, :extrinsic_hash, :call_index, :params_raw, :params

      def self.generate_hash(bytes)
        Crypto.blake2_256 bytes
      end

      def self.decode(scale_bytes)
        metadata = Scale::TypeRegistry.instance.metadata.value
        result = {}

        extrinsic_length = Compact.decode(scale_bytes).value
        # TODO: legacy version

        version_info = scale_bytes.get_next_bytes(1).bytes_to_hex
        contains_transaction = version_info.to_i(16) >= 80

        if version_info == "0x01" || version_info == "0x81"

          if contains_transaction
            address = Scale::Types.get("Address").decode(scale_bytes)
            result[:address] = address.value
            result[:signature] = Scale::Types.get("Signature").decode(scale_bytes).value
            result[:nonce] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:era] = Scale::Types.get("Era").decode(scale_bytes).value
            result[:extrinsic_hash] = generate_hash(scale_bytes.bytes)
          end
          result[:call_index] = scale_bytes.get_next_bytes(2).bytes_to_hex[2..]

        elsif version_info == "0x02" || version_info == "0x82"

          if contains_transaction
            address = Scale::Types.get("Address").decode(scale_bytes)
            result[:address] = address.value
            result[:signature] = Scale::Types.get("Signature").decode(scale_bytes).value
            result[:era] = Scale::Types.get("Era").decode(scale_bytes).value
            result[:nonce] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:tip] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:extrinsic_hash] = generate_hash(scale_bytes.bytes)
          end
          result[:call_index] = scale_bytes.get_next_bytes(2).bytes_to_hex[2..]

        elsif version_info == "0x03" || version_info == "0x83"

          if contains_transaction
            address = Scale::Types.get("Address").decode(scale_bytes)
            result[:address] = address.value
            result[:signature] = Scale::Types.get("Signature").decode(scale_bytes).value
            result[:era] = Scale::Types.get("Era").decode(scale_bytes).value
            result[:nonce] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:tip] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:extrinsic_hash] = generate_hash(scale_bytes.bytes)
          end
          result[:call_index] = scale_bytes.get_next_bytes(2).bytes_to_hex[2..]

        elsif version_info == "0x04" || version_info == "0x84"

          if contains_transaction
            result[:address] = Scale::Types.get("Address").decode(scale_bytes).value
            result[:signature] = Scale::Types.get("MultiSignature").decode(scale_bytes).value
            result[:era] = Scale::Types.get("Era").decode(scale_bytes).value
            result[:nonce] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:tip] = Scale::Types.get("Compact").decode(scale_bytes).value
            result[:extrinsic_hash] = generate_hash(scale_bytes.bytes)
          end
          result[:call_index] = scale_bytes.get_next_bytes(2).bytes_to_hex[2..]

        else
          raise "Extrinsic version #{version_info} is not implemented"
        end

        if result[:call_index]
          call_module, call = metadata.call_index[result[:call_index]]

          result[:call_function] = call[:name].downcase
          result[:call_module] = call_module[:name].downcase

          # decode params
          result[:params_raw] = scale_bytes.get_remaining_bytes.bytes_to_hex
          result[:params] = call[:args].map do |arg|
            type = arg[:type]
            scale_type = Scale::Types.get(type)
            obj = scale_type.decode(scale_bytes)
            {name: arg[:name], type: type, scale_type: scale_type, value: obj.value }
          end
        end

        result[:extrinsic_length] = extrinsic_length
        result[:version_info] = version_info

        Extrinsic.new result
      end

      def encode
        version_info = '84'
        if value.has_key?(:account_id) && !value.has_key?(:address)
          value[:address] = value[:account_id]
        end
        if value.has_key?(:address)
          contains_transaction = true
        end

        if contains_transaction
          data = '84'
          data += Scale::Types.get("Address").new(value[:account_id]).encode()
          data += Scale::Types.get("MultiSignature").new(value[:signature]).encode()
          data += value[:era]
          data += Scale::Types.get("Compact<U32>").new(value[:nonce]).encode()
          data += Scale::Types.get("Compact<Index>").new(value[:tip]).encode()
        else
          data = "04"
        end
        data += value[:call].encode

        length_obj = Scale::Types.get('Compact<U32>').new(data.length / 2)
        length_obj.encode + data
      end

      def to_human
        @value
      end
    end

    class Phase
      include Enum
      items isApplyExtrinsic: "Bool", asApplyExtrinsic: "U32", isFinalization: "Bool", isInitialization: "Bool"
    end

    class EventRecords
      include Base
      
      def self.decode(scale_bytes)

        length = Compact.decode(scale_bytes).value

        length.times do |i|
          ev = EventRecord.decode(scale_bytes)
        end
      end
    end

    class EventRecord
      include Base

      def self.decode(scale_bytes)
        metadata = Scale::TypeRegistry.instance.metadata.value

        result = {}
        phase = scale_bytes.get_next_bytes(1).first

        if phase == 0
          result[:extrinsic_idx] = U32.decode(scale_bytes).value
        end

        index = scale_bytes.get_next_bytes(2).bytes_to_hex[2..]
        event = metadata.event_index[index][1]
        the_module = metadata.event_index[index][0]

        result[:event_index] = index
        result[:event_metadata] = event
        result[:module_metadata] = the_module

        result[:params] = []
        event[:args].each do |arg_type|
          value = Scale::Types.get(arg_type).decode(scale_bytes).to_human
          result[:params] << {
            name: event[:name],
            type: arg_type,
            value: value
          }
        end

        result[:topics] = Scale::Types.get("Vec<Hash>").decode(scale_bytes).value.map(&:value)

        EventRecord.new(result)
      end
    end

    class AuthoritiesChange 
      include Vec
      inner_type "AccountId"
    end

    class GenericConsensusEngineId < VecU8Length4; end

    class ChangesTrieRoot < Bytes; end

    # log
    class Other < Bytes; end

    class SealV0
      include Struct
      items(
        slot: "U64",
        signature: "Signature"
      )
    end

    class Consensus
      include Struct
      items(
        engine: "ConsensusEngineId",
        data: "Hex"
      )
    end

    class Seal
      include Struct
      items(
        engine: "ConsensusEngineId",
        data: "Hex"
      )
    end

    class PreRuntime
      include Struct
      items(
        engine: "ConsensusEngineId",
        data: "Hex"
      )
    end

    class LogDigest
      include Enum
      inner_types *%w[Other AuthoritiesChange ChangesTrieRoot SealV0 Consensus Seal PreRuntime]
    end

  end
end
