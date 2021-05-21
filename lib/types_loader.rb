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

      default_types, _, _ = load_chain_spec_types("default")

      if spec_name
        begin
          @spec_name = spec_name
          spec_types, @versioning, @spec_version = load_chain_spec_types(spec_name)
          @types = default_types.merge(spec_types)
        rescue => ex
          puts "There is no types json file named #{spec_name}"
          @types = default_types
        end
      else
        @spec_name = "default"
        @types = default_types
      end

      self.custom_types = custom_types
      true
    end

    def get(type_name)
      all_types = self.all_types
      type = type_traverse(type_name, all_types)

      Scale::Types.constantize(type)
    end

    def custom_types=(custom_types)
      @custom_types = custom_types.stringify_keys if (not custom_types.nil?) && custom_types.class.name == "Hash"
    end

    def all_types
      all_types = {}.merge(@types)

      if @spec_version && @versioning
        @versioning.each do |item|
          if @spec_version >= item["runtime_range"][0] && 
              ( item["runtime_range"][1].nil? || @spec_version <= item["runtime_range"][1] )
            all_types.merge!(item["types"])
          end
        end
      end

      all_types.merge!(@custom_types) if @custom_types
      all_types
    end

    def check_types
      self.all_types.keys.each do |key|
        begin
          type = self.get(key)
        rescue => ex
          puts "[[ERROR]] #{key}: #{ex}"
        end
      end
      ""
    end

    private

      def load_chain_spec_types(spec_name)
        file = File.join File.expand_path("../..", __FILE__), "lib", "type_registry", "#{spec_name}.json"
        json_string = File.open(file).read
        json = JSON.parse(json_string)

        runtime_id = json["runtime_id"]

        [json["types"], json["versioning"], runtime_id]
      end

      def type_traverse(type, types)
        type = rename(type) if type.class == ::String
        if types.has_key?(type) && types[type] != type
          type_traverse(types[type], types)
        else
          type
        end
      end
  end
end
