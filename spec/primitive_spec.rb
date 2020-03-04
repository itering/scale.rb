require "scale"

module Scale
  module Types

    describe Address do
      it "" do
        scale_bytes = Scale::Bytes.new("0x45")
        o = U8.decode scale_bytes
        expect(o.value).to eql(69)
        expect(o.encode).to eql("45")
      end
    end

  end
end
