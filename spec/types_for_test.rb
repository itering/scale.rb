module Scale
  module Types
    class IntOrBool
      include Enum
      items Int: "U8", Bool: "Bool"
    end

    class VecU8
      include Vec
      inner_type "U8"
    end

    class OptionBool
      include Option
      INNER_TYPE_STR = "boolean".freeze
    end

    class OptionU32
      include Option
      INNER_TYPE_STR = "U32".freeze
    end

    class Student
      include Struct
      items(
        age: "U32",
        grade: "U8",
        courses_number: "OptionU32",
        int_or_bool: "IntOrBool"
      )
    end

    class TupleDoubleU8
      include Tuple
      inner_types "U8", "U8"
    end
  end
end
