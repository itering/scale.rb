module Scale
  module Types

    class IntOrBool
      include Enum
      MEMBERS = [ :Int, :Bool ]
      MEMBER_TYPES = [ Scale::Types::U8, Scale::Types::Bool ]
    end

  end
end
