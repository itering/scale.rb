
        # 2. ["Compact", "Hex"]
        # def build_enum(type_def)
        #   # [["Item1", "Compact"], [["Item2", "Hex"]]
        #   if type_def.has_key?("type_mapping")
        #     items = type_def["type_mapping"].map do |item|
        #       item_name = item[0]
        #       item_type = build(item[1])
        #       [item_name, item_type]
        #     end

        #     type_name = "Enum#{items.map {|item| item[1].name.gsub('Scale::Types::', '') }.join}"

        #     if !Scale::Types.const_defined?(type_name)
        #       klass = Class.new do
        #         include Scale::Types::Enum
        #         items items
        #       end

        #       return Scale::Types.const_set type_name, klass
        #     else
        #       return Scale::Types.const_get type_name
        #     end
        #             end
        #   end

          # # [1, "hello"]
          # if type_def.has_key?(type["value_list"])
          #   klass = Class.new do
          #     include Scale::Types::Enum
          #     values *type["value_list"]
          #   end

          #   type_name = "Enum_#{klass.object_id}"

          #   if !Scale::Types.const_defined?(type_name)
          #     return Scale::Types.const_set type_name, klass
          #   else
          #     return Scale::Types.const_get type_name
          #   end
          # end
          # end

