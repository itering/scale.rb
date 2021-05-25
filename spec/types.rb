module Scale
  module Types
    class IntOrBool
      include Enum
      items(
        Int: Scale::Types::U8, 
        Bool: Scale::Types::Bool
      )
    end

    class OptionU32
      include Option
      inner_type "U32"
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
