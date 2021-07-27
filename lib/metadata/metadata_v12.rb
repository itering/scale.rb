module Scale
  module Types
    class MetadataV12
      include Base
      attr_accessor :call_index, :event_index

      def initialize(value)
        @call_index = {}
        @event_index = {}
        super(value)
      end

      def self.decode(scale_bytes)
        modules = Scale::Types.get("Vec<MetadataV12Module>").decode(scale_bytes).value

        value = {
          magicNumber: 1_635_018_093,
          metadata: {
            version: 12,
            modules: modules.map(&:value)
          }
        }

        result = MetadataV12.new(value)

        call_module_index = 0
        event_module_index = 0

        modules.map(&:value).each do |m|
          module_index = m[:index]
          if m[:calls]
            m[:calls].each_with_index do |call, index|
              call[:lookup] = "%02x%02x" % [module_index, index]
              result.call_index[call[:lookup]] = [m, call]
            end
          end

          if m[:events]
            m[:events].each_with_index do |event, index|
              event[:lookup] = "%02x%02x" % [module_index, index]
              result.event_index[event[:lookup]] = [m, event]
            end
          end
        end

        result
      end
    end

    class MetadataV12Module
      include Base
      def self.decode(scale_bytes)
        name = String.decode(scale_bytes).value

        result = {
          name: name
        }

        has_storage = Bool.decode(scale_bytes).value
        if has_storage
          storage = MetadataV7ModuleStorage.decode(scale_bytes).value
          result[:storage] = storage
          result[:prefix] = storage[:prefix]
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

        result[:constants] = Scale::Types.get("Vec<MetadataV7ModuleConstants>").decode(scale_bytes).value.map(&:value)
        result[:errors] = Scale::Types.get("Vec<MetadataModuleError>").decode(scale_bytes).value.map(&:value)

        result[:index] = U8.decode(scale_bytes).value
        MetadataV12Module.new(result)
      end
    end
  end
end
