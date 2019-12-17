module Scale
  module Types

    class MetadataV7
      include SingleValue
      def self.decode(scale_bytes)
        modules = type("Vec<MetadataV7Module>").decode(scale_bytes).value;
        result = {
          magicNumber: 1635018093,
          metadata: {
            V7: {
              modules: modules.map(&:value)
            }
          }
        }

        MetadataV7.new(result)
      end
    end

    class MetadataV7Module
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
          calls = type("Vec<MetadataModuleCall>").decode(scale_bytes).value
          result[:calls] = calls.map(&:value)
        end

        has_events = Bool.decode(scale_bytes).value
        if has_events
          events = type("Vec<MetadataModuleEvent>").decode(scale_bytes).value
          result[:events] = events.map(&:value)
        end

        result[:constants] = type("Vec<MetadataV7ModuleConstants>").decode(scale_bytes).value.map(&:value)

        MetadataV7Module.new(result)
      end
    end

    class MetadataV7ModuleStorage
      include SingleValue
      def self.decode(scale_bytes)
        prefix = String.decode(scale_bytes).value
        items = type("Vec<MetadataV7ModuleStorageEntry>").decode(scale_bytes).value.map(&:value)
        result = {
          prefix: prefix,
          items: items
        }

        MetadataV7ModuleStorage.new(result)
      end
    end

    class MetadataV7ModuleStorageEntry
      include SingleValue
      def self.decode(scale_bytes)
        result = {
          name: String.decode(scale_bytes).value,
          modifier: type("Enum", values: ["Optional", "Default"]).decode(scale_bytes).value
        }
        storage_function_type = type("Enum", values: ["Plain", "Map", "DoubleMap"]).decode(scale_bytes).value
        if storage_function_type == "Plain"
          result[:type] = {
            Plain: adjust(String.decode(scale_bytes).value)
          }
        elsif storage_function_type == "Map"
          result[:type] = {
            Map: {
              hasher: StorageHasher.decode(scale_bytes).value,
              key: adjust(String.decode(scale_bytes).value),
              value: adjust(String.decode(scale_bytes).value),
              linked: Bool.decode(scale_bytes).value
            }
          }
        elsif storage_function_type == "DoubleMap"
          result[:type] = {
            DoubleMap: {
              hasher: StorageHasher.decode(scale_bytes).value,
              key1: adjust(String.decode(scale_bytes).value),
              key2: adjust(String.decode(scale_bytes).value),
              value: adjust(String.decode(scale_bytes).value),
              key2Hasher: StorageHasher.decode(scale_bytes).value
            }
          }
        end

        result[:fallback] = Hex.decode(scale_bytes).value
        result[:docs] = type("Vec<String>").decode(scale_bytes).value.map(&:value)

        MetadataV7ModuleStorageEntry.new(result)
      end
    end

    class MetadataV7ModuleConstants
      include SingleValue
      def self.decode(scale_bytes)
        result = {
          name: String.decode(scale_bytes).value,
          type: String.decode(scale_bytes).value, # convert
          value: Hex.decode(scale_bytes).value,
          docs: type("Vec<String>").decode(scale_bytes).value.map(&:value)
        }
        MetadataV7ModuleConstants.new result
      end
    end

  end
end
