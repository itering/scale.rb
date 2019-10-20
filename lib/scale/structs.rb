module Scale
  module Types

    class Student
      include Struct
      items(
        age: 'Scale::Types::U32',
        grade: 'Scale::Types::U8',
        courses_number: 'Scale::Types::OptionU32', # 选修课数量, nil表示还没有选
        int_or_bool: 'Scale::Types::IntOrBool'
      )
    end

  end
end
