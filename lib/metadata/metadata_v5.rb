module Scale
  module Types
    class MetadataV5
      include Base
      attr_accessor :call_index, :event_index

      def initialize(value)
        @call_index = {}
        @event_index = {}
        super(value)
      end

      def self.decode(scale_bytes)
        modules = Scale::Types.get("Vec<MetadataV5Module>").decode(scale_bytes).value

        value = {
          magicNumber: 1_635_018_093,
          metadata: {
            version: 5,
            modules: modules.map(&:value)
          }
        }

        result = MetadataV5.new(value)

        call_module_index = 0
        event_module_index = 0

        modules.map(&:value).each do |m|
          if m[:calls]
            m[:calls].each_with_index do |call, index|
              call[:lookup] = "%02x%02x" % [call_module_index, index]
              result.call_index[call[:lookup]] = [m, call]
            end
            call_module_index += 1
          end

          if m[:events]
            m[:events].each_with_index do |event, index|
              event[:lookup] = "%02x%02x" % [event_module_index, index]
              result.event_index[event[:lookup]] = [m, event]
            end
            event_module_index += 1
          end
        end

        result
      end
    end

    class MetadataV5Module
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
          storages = Scale::Types.get("Vec<MetadataV5ModuleStorage>").decode(scale_bytes).value
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

        MetadataV5Module.new(result)
      end
    end

    class MetadataV5ModuleStorage
      include Base
      def self.decode(scale_bytes)
        name = String.decode(scale_bytes).value
        modifier_enum = {
          "type" => "enum",
          "value_list" => ["Optional", "Default"]
        }
        modifier = Scale::Types.get(modifier_enum).decode(scale_bytes).value
        result = {
          name: name,
          modifier: modifier
        }

        storage_function_type_enum = {
          "type" => "enum",
          "value_list" => %w[Plain Map DoubleMap]
        }
        storage_function_type = Scale::Types.get(storage_function_type_enum).decode(scale_bytes).value
        if storage_function_type == "Plain"
          result[:type] = {
            Plain: String.decode(scale_bytes).value
          }
        elsif storage_function_type == "Map"
          result[:type] = {
            Map: {
              hasher: StorageHasher.decode(scale_bytes).value,
              key: String.decode(scale_bytes).value,
              value: String.decode(scale_bytes).value,
              linked: Bool.decode(scale_bytes).value
            }
          }
        elsif storage_function_type == "DoubleMap"
          result[:type] = {
            DoubleMap: {
              hasher: StorageHasher.decode(scale_bytes).value,
              key1: String.decode(scale_bytes).value,
              key2: String.decode(scale_bytes).value,
              value: String.decode(scale_bytes).value,
              key2Hasher: StorageHasher.decode(scale_bytes).value
            }
          }
        end

        result[:fallback] = Hex.decode(scale_bytes).value
        result[:documentation] = Scale::Types.get("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataV5ModuleStorage.new(result)
      end
    end

  end
end
