module Scale
  module Types
    class IntOrBool
      include Enum
      items Int: "U8", Bool: "Bool"
    end

    class OptionU32
      include Option
      inner_type Scale::Types::U32
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
