module Scale
  module Types
    class << self

      # type_info: type_string or type_info
      #   type_string: Compact, H128, Vec<Compact>, (U32, U128), ...
      #   type_def   : struct, enum, set
      #
      # if type_string start_with Scale::Types::, it is treat as a hard coded type
      def get(type_info)
        if type_info.class == ::String 
          if type_info.start_with?('Scale::Types::')

            return get_hard_coded_type(type_info)

          else

            type_registry = TypeRegistry.instance
            if type_registry.types.nil?
              raise TypeRegistryNotLoadYet
            end
            type_info = TypeRegistry.instance.get(type_info)

          end
        end

        if type_info.class == ::String # 1. hard coded types, 2. Vec<...>, 3. Option<...>, 4. [xx; x], 5. (x, y)
          type_string = type_info
          if type_string =~ /\AVec<.+>\z/ 
            build_vec(type_string)
          elsif type_info =~ /\AOption<.+>\z/
            build_option(type_string)
          elsif type_info =~ /\A\[.+;\s*\d+\]\z/
            build_array(type_string)
          elsif type_info =~ /\A\(.+\)\z/
            build_tuple(type_string)
          else
            get_hard_coded_type(type_string)
          end

        else # 5. Struct, 6. Enum, 7. Set

          if type_info["type"] == "struct"
            build_struct(type_info)
          elsif type_info["type"] == "enum"
            build_enum(type_info)
          elsif type_info["type"] == "set"
            build_set(type_info)
          else
            raise Scale::TypeBuildError.new("Failed to build a type from #{type_info}")
          end

        end
      end

      private

        def get_hard_coded_type(type_string)
          type_name = rename(type_string)
          type_name = (type_name.start_with?("Scale::Types::") ? type_name : "Scale::Types::#{type_name}")
          type_name.constantize2
        rescue => e
          raise Scale::TypeBuildError.new("Failed to get the hard coded type named `#{type_string}`")
        end

        def build_vec(type_string)
          inner_type_str = type_string.scan(/\AVec<(.+)>\z/).first.first
          inner_type = get(inner_type_str)

          type_name = "Vec_#{inner_type.name.gsub('Scale::Types::', '')}_"

          if !Scale::Types.const_defined?(type_name)
            klass = Class.new do
              include Scale::Types::Vec
              inner_type inner_type
            end
            Scale::Types.const_set type_name, klass
          else
            Scale::Types.const_get type_name
          end
        end

        def build_option(type_string)
          inner_type_str = type_string.scan(/\AOption<(.+)>\z/).first.first
          inner_type = get(inner_type_str)

          type_name = "Option_#{inner_type.name.gsub('Scale::Types::', '')}_"

          if !Scale::Types.const_defined?(type_name)
            klass = Class.new do
              include Scale::Types::Option
              inner_type inner_type
            end
            Scale::Types.const_set type_name, klass
          else
            Scale::Types.const_get type_name
          end
        end

        def build_array(type_string)
          scan_result = type_string.scan /\[(.+);\s*(\d+)\]/

          #
          inner_type_str = scan_result[0][0]
          inner_type = get(inner_type_str)

          #
          len = scan_result[0][1].to_i

          type_name = "Array_#{inner_type.name.gsub('Scale::Types::', '')}_#{len}_"

          if !Scale::Types.const_defined?(type_name)
            klass = Class.new do
              include Scale::Types::Array
              inner_type inner_type
              length len
            end
            Scale::Types.const_set type_name, klass
          else
            Scale::Types.const_get type_name
          end
        end

        def build_tuple(type_string)
          scan_result = type_string.scan /\A\((.+)\)\z/
          inner_types_str = scan_result[0][0]
          inner_type_strs = inner_types_str.split(",").map do |inner_type_str| 
            inner_type_str.strip
          end

          inner_types = inner_type_strs.map do |inner_type_str|
            get(inner_type_str)
          end

          type_name = "Tuple_#{inner_types.map {|inner_type| inner_type.name.gsub('Scale::Types::', '')}.join("_")}_"
          if !Scale::Types.const_defined?(type_name)
            klass = Class.new do
              include Scale::Types::Tuple
              inner_types(*inner_types)
            end
            Scale::Types.const_set type_name, klass
          else
            Scale::Types.const_get type_name
          end
        end

        def build_struct(type_info)
          # items: {"a" => Type}
          items = type_info["type_mapping"].map do |item|
            item_name = item[0]
            item_type = get(item[1])
            [item_name, item_type]
          end.to_h

          partials = []
          items.each_pair do |item_name, item_type|
            partials << item_name.camelize2 + 'In' + item_type.name.gsub('Scale::Types::', '') 
          end
          type_name = "Struct_#{partials.join('_')}_"

          if !Scale::Types.const_defined?(type_name)
            klass = Class.new do
              include Scale::Types::Struct
              items(**items)
            end
            Scale::Types.const_set type_name, klass
          else
            Scale::Types.const_get type_name
          end
        end

        # not implemented: ["Compact", "Hex"]
        def build_enum(type_info)
          # type_info: [["Item1", "Compact"], [["Item2", "Hex"]]
          if type_info.has_key?("type_mapping")
            # items: {a: Type}
            items = type_info["type_mapping"].map do |item|
              item_name = item[0]
              item_type = get(item[1])
              [item_name.to_sym, item_type]
            end.to_h

            partials = []
            items.each_pair do |item_name, item_type|
              partials << item_name.to_s.camelize2 + 'In' + item_type.name.gsub('Scale::Types::', '') 
            end
            type_name = "Enum_#{partials.join('_')}_"

            if !Scale::Types.const_defined?(type_name)
              klass = Class.new do
                include Scale::Types::Enum
                items(**items)
              end

              return Scale::Types.const_set type_name, klass
            else
              return Scale::Types.const_get type_name
            end
          end

          # [1, "hello"]
          if type_info.has_key?("value_list")
            type_name = "Enum#{type_info["value_list"].map {|value| value.to_s.camelize2}.join}"

            if !Scale::Types.const_defined?(type_name)
              klass = Class.new do
                include Scale::Types::Enum
                values *type_info["value_list"]
              end
              return Scale::Types.const_set type_name, klass
            else
              return Scale::Types.const_get type_name
            end
          end
        end


        # {
          # value_type: u32,
          # value_list: {
          #   "TransactionPayment" => 0b00000001,
          #   "Transfer" => 0b00000010,
          #   "Reserve" => 0b00000100,
          #   ...
          # }
        # }
        def build_set(type_info)
          type_name = "Set#{type_info["value_list"].keys.map(&:camelize2).join("")}"
          if !Scale::Types.const_defined?(type_name)
            bytes_length = type_info["value_type"][1..].to_i / 8
            klass = Class.new do
              include Scale::Types::Set
              items type_info["value_list"], bytes_length
            end
            return Scale::Types.const_set type_name, klass
          else
            return Scale::Types.const_get type_name
          end
          Scale::Types.const_set fix(name), klass
        end

        def rename(type)
          type = type.gsub("T::", "")
            .gsub("<T>", "")
            .gsub("<T as Trait>::", "")
            .delete("\n")
            .gsub("EventRecord<Event, Hash>", "EventRecord")
            .gsub(/(u)(\d+)/, 'U\2')
          return "Bool" if type == "bool"
          return "Null" if type == "()"
          return "String" if type == "Vec<u8>"
          return "Compact" if type == "Compact<u32>" || type == "Compact<U32>"
          return "Address" if type == "<Lookup as StaticLookup>::Source"
          return "Vec<Address>" if type == "Vec<<Lookup as StaticLookup>::Source>"
          return "Compact" if type == "<Balance as HasCompact>::Type"
          return "Compact" if type == "<BlockNumber as HasCompact>::Type"
          return "Compact" if type =~ /\ACompact<[a-zA-Z0-9\s]*>\z/
          return "CompactMoment" if type == "<Moment as HasCompact>::Type"
          return "CompactMoment" if type == "Compact<Moment>"
          return "InherentOfflineReport" if type == "<InherentOfflineReport as InherentOfflineReport>::Inherent"
          return "AccountData" if type == "AccountData<Balance>"

          type
        end

    end
  end
end
