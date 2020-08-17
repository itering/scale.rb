module Scale
  module Types
    class MetadataV4
      include SingleValue
      attr_accessor :call_index, :event_index

      def initialize(value)
        @call_index = {}
        @event_index = {}
        super(value)
      end

      def self.decode(scale_bytes)
        modules = Scale::Types.type_of("Vec<MetadataV4Module>").decode(scale_bytes).value

        value = {
          magicNumber: 1_635_018_093,
          metadata: {
            version: 4,
            modules: modules.map(&:value)
          }
        }

        result = MetadataV4.new(value)

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

    class MetadataV4Module
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
          storages = Scale::Types.type_of("Vec<MetadataV4ModuleStorage>").decode(scale_bytes).value
          result[:storage] = storages.map(&:value)
        end

        has_calls = Bool.decode(scale_bytes).value
        if has_calls
          calls = Scale::Types.type_of("Vec<MetadataModuleCall>").decode(scale_bytes).value
          result[:calls] = calls.map(&:value)
        end

        has_events = Bool.decode(scale_bytes).value
        if has_events
          events = Scale::Types.type_of("Vec<MetadataModuleEvent>").decode(scale_bytes).value
          result[:events] = events.map(&:value)
        end

        MetadataV4Module.new(result)
      end
    end

    class MetadataV4ModuleStorage
      include SingleValue
      def self.decode(scale_bytes)
        result = {
          name: String.decode(scale_bytes).value,
          modifier: Scale::Types.type_of("Enum", %w[Optional Default]).decode(scale_bytes).value
        }

        storage_function_type = Scale::Types.type_of("Enum", %w[Plain Map DoubleMap]).decode(scale_bytes).value
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
        result[:documentation] = Scale::Types.type_of("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataV4ModuleStorage.new(result)
      end
    end

  end
end
