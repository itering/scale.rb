module Scale
  module Types

    class OptionBool
      include Option
      INNER_TYPE_STR = 'boolean'
    end

    class OptionU32
      include Option
      INNER_TYPE_STR = 'U32'
    end

    class OptionStudent
      include Option
      INNER_TYPE_STR = 'Student'
    end

  end
end
