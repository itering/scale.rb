require "scale"
require_relative "./types.rb"
require_relative "./ffi_helper.rb"

module Scale
  module Types

    describe Types do
      it "should work correctly" do
        parse_via_ffi(45, U8)
        parse_via_ffi(16_777_215, U32)
        parse_via_ffi(14_294_967_296, U64)
        parse_via_ffi(false, Bool)
        parse_via_ffi(true, Bool)
        parse_via_ffi(nil, OptionBool)

        # Rust SCALE does not implement Optional Booleans conformant to
        # specification yet, so this is commented for now
        # parse_via_ffi(false, OptionBool)

        # Rust SCALE does not implement Optional Booleans conformant to
        # specification yet, so this is commented for now
        # parse_via_ffi(o.value, OptionBool)

        parse_via_ffi(nil, OptionU32)
        # parse_via_ffi(16_777_215, OptionU32)
      end
    end

  end
end

def parse_via_ffi_plus_spec(value, encoding, expecation)
  encoded = encoding.new(value).encode
  check_against_specification(encoded, expecation)
  parse_via_ffi(value, encoding)
end

# U64
puts "\nU64 tests"
parse_via_ffi_plus_spec(14_294_967_296, Scale::Types::U64, "00e40b5403000000")

# U32
puts "\nU32 tests"
parse_via_ffi_plus_spec(16_777_215, Scale::Types::U32, "ffffff00")
parse_via_ffi_plus_spec(4_294_967_041, Scale::Types::U32, "01ffffff")

# U8
puts "\nU8 tests"
parse_via_ffi_plus_spec(69, Scale::Types::U8, "45")

# Bool
puts "\nBool tests"
parse_via_ffi_plus_spec(true, Scale::Types::Bool, "01")
parse_via_ffi_plus_spec(false, Scale::Types::Bool, "00")

# Optional U32
puts "\nOptional U32 tests"
parse_via_ffi_plus_spec(nil, Scale::Types::OptionU32, "00")
parse_via_ffi_plus_spec(
  Scale::Types::U32.new(16_777_215),
  Scale::Types::OptionU32,
  "01ffffff00"
)
