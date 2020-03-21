module Scale
  module Types
    class MetadataV0
      include SingleValue
      attr_accessor :call_index, :event_index

      def initialize(value)
        @call_index = {}
        @event_index = {}
        super(value)
      end

      def self.decode(scale_bytes)
        # modules = Scale::Types.type_of('Vec<MetadataModule>').decode(scale_bytes).value

        value = {
          metadata: {
            V0: {
              outerEvent: {
                name: Bytes.decode(scale_bytes).value,
                events: []
              },
              modules: [],
              sections: []
            }
          }
        }

        events_modules = Scale::Types.type_of("Vec<MetadataV0EventModule>").decode(scale_bytes).value.map(&:value)
        modules = Scale::Types.type_of("Vec<MetadataV0Module>").decode(scale_bytes).value.map(&:value)

        Bytes.decode(scale_bytes).value

        sections = Scale::Types.type_of("Vec<MetadataV0Section>").value.map(&:value)

        value[:metadata][:V0][:outerEvent][:events] = events_modules
        value[:metadata][:V0][:modules] = modules
        value[:metadata][:V0][:sections] = sections

        result = MetadataV0.new(value)

        # call_module_index = 0
        # event_module_index = 0

        # modules.map(&:value).each do |m|
          # if m[:calls]
            # m[:calls].each_with_index do |call, index|
              # call[:lookup] = "%02x%02x" % [call_module_index, index]
              # result.call_index[call[:lookup]] = [m, call]
            # end
            # call_module_index += 1
          # end

          # if m[:events]
            # m[:events].each_with_index do |event, index|
              # event[:lookup] = "%02x%02x" % [call_module_index, index]
              # result.event_index[event[:lookup]] = [m, event]
            # end
            # event_module_index += 1
          # end
        # end

        result
      end
    end

    class MetadataV0EventModule
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        events = Scale::Types.type_of('Vec<MetadataV0Event>').decode(scale_bytes).value.map(&:value)
        MetadataV0EventModule.new({name: name, events: events})
      end
    end

    class MetadataV0Event
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        args = Scale::Types.type_of("Vec<Bytes>").decode(scale_bytes).value.map(&:value)
        docs = Scale::Types.type_of("Vec<Bytes>").decode(scale_bytes).value.map(&:value)
        MetadataV0Event.new({name: name, args: args, docs: docs})
      end
    end

    class MetadataV0Module
      include SingleValue

      def self.decode(scale_bytes)
        prefix = Bytes.decode(scale_bytes).value
        name = Bytes.decode(scale_bytes).value
        call_name = Bytes.decode(scale_bytes).value
        
        functions = Scale::Types.type_of("Vec<MetadataV0ModuleFunction>").decode(scale_bytes).value.map(&:value)

        result = {
            prefix: prefix,
            index: nil,
            module: {
                name: name,
                call: {
                    name: call_name,
                    functions: functions
                }
            }
        }

        has_storage = Bool.decode(scale_bytes).value
        if has_storage
          storage_prefix = Bytes.decode(scale_bytes).value
          storage = Scale::Types.type_of("Vec<MetadataV0ModuleStorage>").decode(scale_bytes).value.map(&:value)
          result[:storage] = {
            prefix: storage_prefix,
            functions: storage
          }
        end

        MetadataV0Module.new(result)
      end
    end

    class MetadataV0ModuleFunction
      include SingleValue

      def self.decode(scale_bytes)
        id = scale_bytes.get_next_bytes(2).bytes_to_hex
        name = Bytes.decode(scale_bytes).value
        args = Scale::Types.type_of("Vec<MetadataModuleCallArgument>").decode(scale_bytes).value.map(&:value)
        docs = Scale::Types.type_of("Vec<Bytes>").decode(scale_bytes).value.map(&:value)
        MetadataV0ModuleFunction.new({
          id: id,
          name: name,
          args: args,
          docs: docs
        })
      end
    end

    class MetadataModuleCallArgument
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        type = adjust(Bytes.decode(scale_bytes).value)

        MetadataModuleCallArgument.new({name: name, type: type})
      end
    end

    class MetadataV0ModuleStorage
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        modifier = Scale::Types.type_of("Enum", ["Optional", "Default"]).decode(scale_bytes).value

        is_key_value = Bool.decode(scale_bytes).value

        if is_key_value
          type = {
            MapType: {
              key: adjust(Bytes.decode(scale_bytes).value),
              value: adjust(Bytes.decode(scale_bytes).value)
            }
          }
        else
          type = {
            PlainType: adjust(Bytes.decode(scale_bytes).value)
          }
        end

        fallback = Hex.decode(scale_bytes).value
        docs = Scale::Types.type_of("Vec<Bytes>").decode(scale_bytes).value

        MetadataV0ModuleStorage.new({
          name: name,
          modifier: modifier,
          type: type,
          default: fallback,
          docs: docs
        })
      end
    end

  end
end
