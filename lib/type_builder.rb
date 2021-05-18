module Scale
  module Types
    class << self

      def build(type_def)
        if type_def.class == ::String # 1. Primitive types, 2. Vec<...>, 3. Option<...>, 4. [xx; x], 5. (x, y)

          if type_def =~ /\AVec<.+>\z/ 
            build_vec(type_def)
          elsif type_def =~ /\AOption<.+>\z/
            build_option(type_def)
          elsif type_def =~ /\A\[.+;\s*\d+\]\z/
            build_array(type_def)
          else
            build_primitive(type_def)
          end

        else # 5. Struct, 6. Enum, 7. Set
          if type_def["type"] == "struct"
            build_struct(type_def)
          elsif type_def["type"] == "enum"
            build_enum(type_def)
          end
        end
      end

      def build_primitive(type_string)
        type_name = (type_string.start_with?("Scale::Types::") ? type_string : "Scale::Types::#{type_string}")
        type_name.constantize2
      rescue NameError => e
        puts "#{type_string} is not defined"
      end

      def build_vec(type_string)
        inner_type_str = type_string.scan(/\AVec<(.+)>\z/).first.first
        inner_type = build(inner_type_str)

        type_name = "Vec#{inner_type.name.gsub('Scale::Types::', '')}"

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
        inner_type = build(inner_type_str)

        type_name = "Option#{inner_type.name.gsub('Scale::Types::', '')}"

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
        inner_type = build(inner_type_str)

        type_name = "Array#{inner_type.name.gsub('Scale::Types::', '')}"

        #
        len = scan_result[0][1].to_i

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

      def build_struct(type_def)
        items = type_def["type_mapping"].map do |item|
          item_name = item[0]
          item_type = build(item[1])
          [item_name, item_type]
        end

        type_name = "Struct#{items.map {|item| item[1].name.gsub('Scale::Types::', '') }.join}"

        if !Scale::Types.const_defined?(type_name)
          klass = Class.new do
            include Scale::Types::Struct
            items items
          end
          Scale::Types.const_set type_name, klass
        else
          Scale::Types.const_get type_name
        end
      end

      # ["Compact", "Hex"]
      def build_enum(type_def)
        # [["Item1", "Compact"], [["Item2", "Hex"]]
        if type_def.has_key?("type_mapping")
          items = type_def["type_mapping"].map do |item|
            item_name = item[0]
            item_type = build(item[1])
            [item_name, item_type]
          end

          type_name = "Enum#{items.map {|item| item[1].name.gsub('Scale::Types::', '') }.join}"

          if !Scale::Types.const_defined?(type_name)
            klass = Class.new do
              include Scale::Types::Enum
              items items
            end

            return Scale::Types.const_set type_name, klass
          else
            return Scale::Types.const_get type_name
          end
        end

        # [1, "hello"]
        if type_def.has_key?(type["value_list"])
          klass = Class.new do
            include Scale::Types::Enum
            values *type["value_list"]
          end

          type_name = "Enum_#{klass.object_id}"

          if !Scale::Types.const_defined?(type_name)
            return Scale::Types.const_set type_name, klass
          else
            return Scale::Types.const_get type_name
          end
        end
      end

    end
  end
end
