module Scale
  class TypeRegistry
    include Singleton

    # init by load, and will not change
    attr_reader :spec_name, :types
    attr_reader :versioning, :custom_types # optional

    # will change by different spec version
    attr_accessor :spec_version # optional
    attr_accessor :metadata

    def load(spec_name: nil, custom_types: nil)
      @spec_name = nil
      @types = nil
      @versioning = nil
      @custom_types = nil

      default_types, = load_chain_spec_types('default')

      if spec_name
        begin
          @spec_name = spec_name
          spec_types, @versioning, @spec_version = load_chain_spec_types(spec_name)
          @types = default_types.merge(spec_types)
        rescue StandardError => _e
          # TODO: check different errors
          Scale::Types.logger.error "There is no types json file named #{spec_name}"
          @types = default_types
        end
      else
        @spec_name = 'default'
        @types = default_types
      end

      self.custom_types = custom_types
      true
    end

    # get the final type by type name
    # TODO: add cache
    def get(type_name)
      all_types = self.all_types
      if type_name.start_with?('Scale::Types::')
        type_name = type_name[14..]
      end
      final_type = type_traverse(type_name, all_types)
      TypeBuilder.build(final_type)
    end

    def custom_types=(custom_types)
      @custom_types = custom_types.stringify_keys if !custom_types.nil? && custom_types.instance_of?(Hash)
    end

    def all_types
      all_types = {}.merge(@types)

      if @spec_version && @versioning
        @versioning.each do |item|
          if @spec_version >= item['runtime_range'][0] &&
             (item['runtime_range'][1].nil? || @spec_version <= item['runtime_range'][1])
            all_types.merge!(item['types'])
          end
        end
      end

      all_types.merge!(@custom_types) if @custom_types
      all_types
    end

    private

    def load_chain_spec_types(spec_name)
      file = File.join File.expand_path('..', __dir__), 'lib', 'type_registry', "#{spec_name}.json"
      json_string = File.open(file).read
      json = JSON.parse(json_string)

      runtime_id = json['runtime_id']

      [json['types'], json['versioning'], runtime_id]
    end

    # return:
    #   1. type name,
    #   2. type def:
    #     1. Vec<...>, 2. Option<...>, 3. [xx; x], 4. (x, y)
    #     5. struct, 6. enum, 7. set
    def type_traverse(type, types)
      if type.instance_of?(::String)
        fixed_type = TypeBuilder.fix_name(type)
        mapping_type = types[fixed_type]

        return fixed_type if mapping_type.nil? || mapping_type == fixed_type

        type_traverse(mapping_type, types)
      else
        type
      end
    end
  end
end
