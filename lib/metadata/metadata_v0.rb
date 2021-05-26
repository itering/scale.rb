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
        value = {
          metadata: {
            version: 0,
            outerEvent: {
              name: Bytes.decode(scale_bytes).value,
              events: []
            },
            modules: [],
            outerDispatch: {
              name: "Call",
              calls: []
            }
          }
        }

        events_modules = Scale::Types.get("Vec<MetadataV0EventModule>").decode(scale_bytes).value.map(&:value)
        modules = Scale::Types.get("Vec<MetadataV0Module>").decode(scale_bytes).value.map(&:value)

        Bytes.decode(scale_bytes).value

        sections = Scale::Types.get("Vec<MetadataV0Section>").decode(scale_bytes).value.map(&:value)

        value[:metadata][:outerEvent][:events] = events_modules
        value[:metadata][:modules] = modules
        value[:metadata][:outerDispatch][:calls] = sections

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
        events = Scale::Types.get('Vec<MetadataV0Event>').decode(scale_bytes).value.map(&:value)
        MetadataV0EventModule.new([
          name, 
          events
        ])
      end
    end

    class MetadataV0Event
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        args = Scale::Types.get("Vec<Bytes>").decode(scale_bytes).value.map(&:value)
        documentation = Scale::Types.get("Vec<Bytes>").decode(scale_bytes).value.map(&:value)
        MetadataV0Event.new({name: name, args: args.map {|arg| arg }, documentation: documentation})
      end
    end

    class MetadataV0Module
      include SingleValue

      def self.decode(scale_bytes)
        prefix = Bytes.decode(scale_bytes).value
        name = Bytes.decode(scale_bytes).value
        call_name = Bytes.decode(scale_bytes).value

        functions = Scale::Types.get("Vec<MetadataV0ModuleFunction>").decode(scale_bytes).value.map(&:value)

        result = {
            prefix: prefix,
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
          storage = Scale::Types.get("Vec<MetadataV0ModuleStorage>").decode(scale_bytes).value.map(&:value)
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
        id = U16.decode(scale_bytes).value
        name = Bytes.decode(scale_bytes).value
        args = Scale::Types.get("Vec<MetadataV0ModuleCallArgument>").decode(scale_bytes).value.map(&:value)
        documentation = Scale::Types.get("Vec<Bytes>").decode(scale_bytes).value.map(&:value)
        MetadataV0ModuleFunction.new({
          id: id,
          name: name,
          args: args,
          documentation: documentation
        })
      end
    end

    class MetadataV0ModuleCallArgument
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        type = Bytes.decode(scale_bytes).value

        MetadataV0ModuleCallArgument.new({name: name, type: type})
      end
    end

    class MetadataV0ModuleStorage
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        enum = {
          "type" => "enum",
          "value_list" => ["Optional", "Default"]
        }
        modifier = Scale::Types.get(enum).decode(scale_bytes).value

        is_key_value = Bool.decode(scale_bytes).value

        if is_key_value
          type = {
            Map: {
              key: Bytes.decode(scale_bytes).value,
              value: Bytes.decode(scale_bytes).value
            }
          }
        else
          type = {
            Plain: Bytes.decode(scale_bytes).value
          }
        end

        fallback = Hex.decode(scale_bytes).value
        documentation = Scale::Types.get("Vec<Bytes>").decode(scale_bytes).value.map(&:value)

        MetadataV0ModuleStorage.new({
          name: name,
          modifier: modifier,
          type: type,
          fallback: fallback,
          documentation: documentation
        })
      end
    end

    class MetadataV0Section
      include SingleValue

      def self.decode(scale_bytes)
        name = Bytes.decode(scale_bytes).value
        prefix = Bytes.decode(scale_bytes).value
        id = U16.decode(scale_bytes).value
        
        MetadataV0Section.new({
          name: name,
          prefix: prefix,
          index: id
        })
      end
    end

  end
end
