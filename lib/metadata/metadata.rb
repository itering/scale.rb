module Scale
  module Types
    class Metadata
      include Base
      attr_accessor :version
      def self.decode(scale_bytes)
        bytes = scale_bytes.get_next_bytes(4)
        if bytes.bytes_to_utf8 == "meta"
          version_enum = {
            "type" => "enum",
            "value_list" => %w[MetadataV0 MetadataV1 MetadataV2 MetadataV3 MetadataV4 MetadataV5 MetadataV6 MetadataV7 MetadataV8 MetadataV9 MetadataV10 MetadataV11 MetadataV12 MetadataV13]
          }
          metadata_version = Scale::Types.get(version_enum).decode(scale_bytes).value
          metadata = Metadata.new "Scale::Types::#{metadata_version}".constantize2.decode(scale_bytes)
          metadata.version = metadata_version[9..].to_i
        else
          scale_bytes.reset_offset
          metadata_v0 = Scale::Types::MetadataV0.decode(scale_bytes)
          metadata = Metadata.new metadata_v0
          metadata.version = 0
        end
        metadata
      end

      def get_module(module_name)
        modules = self.value.value[:metadata][:modules]
        modules.each do |m|
          if m[:name].downcase == module_name.downcase
            return m
          end
        end
      end

      def get_module_call(module_name, call_name)
        the_module = get_module(module_name)
        the_module[:calls].each do |call|
          if call[:name].downcase == call_name.downcase
            return call
          end
        end
      end

      def get_module_storage(module_name, storage_name)
        the_module = get_module(module_name)
        if the_module[:storage].class == Array
          storages = the_module[:storage]
        else
          storages = the_module[:storage][:items]
        end
        storages.find {|storage| storage[:name] == storage_name}
      end
    end

    class MetadataModule
      include Base
      def self.decode(scale_bytes)
        name = String.decode(scale_bytes).value
        prefix = String.decode(scale_bytes).value

        result = {
          name: name,
          prefix: prefix
        }

        has_storage = Bool.decode(scale_bytes).value
        if has_storage
          storages = Scale::Types.get("Vec<MetadataModuleStorage>").decode(scale_bytes).value
          result[:storage] = storages.map(&:value)
        end

        has_calls = Bool.decode(scale_bytes).value
        if has_calls
          calls = Scale::Types.get("Vec<MetadataModuleCall>").decode(scale_bytes).value
          result[:calls] = calls.map(&:value)
        end

        has_events = Bool.decode(scale_bytes).value
        if has_events
          events = Scale::Types.get("Vec<MetadataModuleEvent>").decode(scale_bytes).value
          result[:events] = events.map(&:value)
        end

        MetadataModule.new(result)
      end

      def get_storage(storage_name)
        self.value[:storage].find { |storage| storage[:name].downcase == storage_name.downcase }
      end
    end

    class MetadataModuleStorage
      include Base
      def self.decode(scale_bytes)
        name = String.decode(scale_bytes).value
        enum = {
          "type" => "enum",
          "value_list" => ["Optional", "Default"]
        }
        modifier = Scale::Types.get(enum).decode(scale_bytes).value
        result = {
          name: name,
          modifier: modifier
        }

        is_key_value = Bool.decode(scale_bytes).value
        result[:type] = if is_key_value
                          {
                            Map: {
                              key: String.decode(scale_bytes).value,
                              value: String.decode(scale_bytes).value,
                              linked: Bool.decode(scale_bytes).value
                            }
                          }
                        else
                          {
                            Plain: String.decode(scale_bytes).value
                          }
                        end

        result[:fallback] = Hex.decode(scale_bytes).value
        result[:documentation] = Scale::Types.get("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataModuleStorage.new(result)
      end
    end

    class MetadataModuleCall
      include Base
      def self.decode(scale_bytes)
        result = {}
        result[:name] = String.decode(scale_bytes).value
        result[:args] = Scale::Types.get("Vec<MetadataModuleCallArgument>").decode(scale_bytes).value.map(&:value)
        result[:documentation] = Scale::Types.get("Vec<String>").decode(scale_bytes).value.map(&:value)
        MetadataModuleCall.new(result)
      end
    end

    class MetadataModuleCallArgument
      include Base
      def self.decode(scale_bytes)
        result = {}
        result[:name] = String.decode(scale_bytes).value
        result[:type] = String.decode(scale_bytes).value

        MetadataModuleCallArgument.new(result)
      end
    end

    class MetadataModuleEvent
      include Base
      def self.decode(scale_bytes)
        result = {}
        result[:name] = String.decode(scale_bytes).value
        result[:args] = Scale::Types.get("Vec<String>").decode(scale_bytes).value.map(&:value)
        result[:documentation] = Scale::Types.get("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataModuleEvent.new(result)
      end
    end
  end
end
