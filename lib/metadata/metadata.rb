module Scale
  module Types

    class Metadata
      include SingleValue
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(4)
        if bytes.bytes_to_utf8 == 'meta'
          metadata_v_name = type("Enum", values: [
            "Scale::Types::MetadataV0", 
            "Scale::Types::MetadataV1", 
            "Scale::Types::MetadataV2", 
            "Scale::Types::MetadataV3",
            "Scale::Types::MetadataV4",
            "Scale::Types::MetadataV5",
            "Scale::Types::MetadataV6",
            "Scale::Types::MetadataV7",
            "Scale::Types::MetadataV8",
            "Scale::Types::MetadataV9",
            "Scale::Types::MetadataV10"
          ]).decode(scale_bytes).value

          Metadata.new(metadata_v_name.constantize.decode(scale_bytes).value)
        end
      end
    end

    class MetadataModule
      include SingleValue
      def self.decode(scale_bytes)
        name = String.decode(scale_bytes).value
        prefix = String.decode(scale_bytes).value

        result = {
          name: name,
          prefix: prefix
        }

        has_storage = Bool.decode(scale_bytes).value
        if has_storage
          storages = type("Vec<MetadataModuleStorage>").decode(scale_bytes).value
          result[:storage] = storages.map(&:value)
        end

        has_calls = Bool.decode(scale_bytes).value
        if has_calls
          calls = type("Vec<MetadataModuleCall>").decode(scale_bytes).value
          result[:calls] = calls.map(&:value)
        end

        has_events = Bool.decode(scale_bytes).value
        if has_events
          events = type("Vec<MetadataModuleEvent>").decode(scale_bytes).value
          result[:events] = events.map(&:value)
        end

        MetadataModule.new(result)
      end
    end

    class MetadataModuleStorage
      include SingleValue
      def self.decode(scale_bytes)

        result = {
          name: String.decode(scale_bytes).value,
          modifier: type("Enum", values: ["Optional", "Default"]).decode(scale_bytes).value
        }

        is_key_value = Bool.decode(scale_bytes).value
        if is_key_value
          result[:type] = {
            Map: {
              key: String.decode(scale_bytes).value,
              value: String.decode(scale_bytes).value,
              linked: Bool.decode(scale_bytes).value
            }
          }
        else
          result[:type] = {
            Plain: String.decode(scale_bytes).value
          }
        end

        result[:fallback] = Hex.decode(scale_bytes).value
        result[:documentation] = type("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataModuleStorage.new(result)
      end
    end

    class MetadataModuleCall
      include SingleValue
      def self.decode(scale_bytes)
        result = {}
        result[:name] = String.decode(scale_bytes).value
        result[:args] = type("Vec<MetadataModuleCallArgument>").decode(scale_bytes).value.map(&:value)
        result[:documentation] = type("Vec<String>").decode(scale_bytes).value.map(&:value)
        MetadataModuleCall.new(result)
      end
    end

    class MetadataModuleCallArgument
      include SingleValue
      def self.decode(scale_bytes)
        result = {}
        result[:name] = String.decode(scale_bytes).value
        result[:type] = String.decode(scale_bytes).value # TODO: convert

        MetadataModuleCallArgument.new(result)
      end
    end

    class MetadataModuleEvent
      include SingleValue
      def self.decode(scale_bytes)
        result = {}
        result[:name] = String.decode(scale_bytes).value
        result[:args] = type("Vec<String>").decode(scale_bytes).value.map(&:value)
        result[:documentation] = type("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataModuleEvent.new(result)
      end
    end

  end
end
