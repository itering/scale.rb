module Scale
  module Types

    class U8
      include FixedWidthUInt
      BYTES_LENGTH = 1
    end

    class U16
      include FixedWidthUInt
      BYTES_LENGTH = 2
    end

    class U32
      include FixedWidthUInt
      BYTES_LENGTH = 4
    end

    class U64
      include FixedWidthUInt
      BYTES_LENGTH = 8
    end

    class U128
      include FixedWidthUInt
      BYTES_LENGTH = 16
    end
  end
end
