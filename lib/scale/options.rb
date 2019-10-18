module Scale
  module Types

    class OptionBool
      include Option
      INNER_TYPE = 'boolean'
    end

    class OptionU32
      include Option
      INNER_TYPE = 'Scale::Types::U32'
    end

    class OptionStudent
      include Option
      INNER_TYPE = 'Scale::Types::Student'
    end

  end
end
