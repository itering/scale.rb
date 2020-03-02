module Scale
  module Types

    class MetadataV8
      include SingleValue
      def self.decode(scale_bytes)
        modules = type_of("Vec<MetadataV8Module>").decode(scale_bytes).value;
        result = {
          magicNumber: 1635018093,
          metadata: {
            V8: {
              modules: modules.map(&:value)
            }
          }
        }

        MetadataV8.new(result)
      end
    end

    class MetadataV8Module
      include SingleValue
      def self.decode(scale_bytes)
        name = String.decode(scale_bytes).value

        result = {
          name: name,
        }

        has_storage = Bool.decode(scale_bytes).value
        if has_storage
          storage = MetadataV7ModuleStorage.decode(scale_bytes).value
          result[:storage] = storage
          result[:prefix] = storage[:prefix]
        end

        has_calls = Bool.decode(scale_bytes).value
        if has_calls
          calls = type_of("Vec<MetadataModuleCall>").decode(scale_bytes).value
          result[:calls] = calls.map(&:value)
        end

        has_events = Bool.decode(scale_bytes).value
        if has_events
          events = type_of("Vec<MetadataModuleEvent>").decode(scale_bytes).value
          result[:events] = events.map(&:value)
        end

        result[:constants] = type_of("Vec<MetadataV7ModuleConstants>").decode(scale_bytes).value.map(&:value)
        result[:errors] = type_of("Vec<MetadataModuleError>").decode(scale_bytes).value.map(&:value)

        MetadataV8Module.new(result)
      end
    end

    class MetadataModuleError
      include SingleValue
      def self.decode(scale_bytes)
        result = {
          name: String.decode(scale_bytes).value,
          docs: type_of("Vec<String>").decode(scale_bytes).value.map(&:value)
        }

        MetadataModuleError.new(result)
      end
    end

  end
end
