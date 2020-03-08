# frozen_string_literal: true

require 'scale'
require_relative './types_for_test.rb'
require 'ffi'

module Rust
  extend FFI::Library
  ffi_lib 'target/debug/libvector_ffi.' + FFI::Platform::LIBSUFFIX
  attach_function :parse_u64, %i[pointer int uint64], :void
  attach_function :parse_u32, %i[pointer int uint32], :void
  attach_function :parse_u8, %i[pointer int uint8], :void
  attach_function :parse_bool, %i[pointer int bool], :void
  attach_function :parse_opt_u32, %i[pointer int uint32 bool], :void
end

parse_u64 = proc { |vec_c, value|
  Rust.parse_u64(vec_c, vec_c.size, value)
}

parse_u32 = proc { |vec_c, value|
  Rust.parse_u32(vec_c, vec_c.size, value)
}

parse_u8 = proc { |vec_c, value|
  Rust.parse_u8(vec_c, vec_c.size, value)
}

parse_bool = proc { |vec_c, value|
  Rust.parse_bool(vec_c, vec_c.size, value)
}

parse_opt_u32 = proc { |vec_c, value|
  if value.nil?
    Rust.parse_opt_u32(vec_c, vec_c.size, 0, false)
  else
    Rust.parse_opt_u32(vec_c, vec_c.size, value.value, true)
  end
}

def check_against_specification(encoded, expectation)
  describe do
    it 'encoding should match specification' do
      expect(encoded).to eql(expectation)
    end
  end
end

def parse_via_ffi(value, encoding, ffi_function, expectation)
  encoded = encoding.new(value).encode
  check_against_specification(encoded, expectation)
  puts encoded
  vec = Scale::Bytes.new('0x' + encoded).bytes
  puts vec

  vec_c = FFI::MemoryPointer.new(:int8, vec.size)
  vec_c.write_array_of_int8 vec
  ffi_function.call(vec_c, value)
end

parse_via_ffi(14_294_967_296, Scale::Types::U64, parse_u64, '00e40b5403000000')

parse_via_ffi(16_777_215, Scale::Types::U32, parse_u32, 'ffffff00')
parse_via_ffi(4_294_967_041, Scale::Types::U32, parse_u32, '01ffffff')

parse_via_ffi(69, Scale::Types::U8, parse_u8, '45')

parse_via_ffi(true, Scale::Types::Bool, parse_bool, '01')
parse_via_ffi(false, Scale::Types::Bool, parse_bool, '00')

parse_via_ffi(nil, Scale::Types::OptionU32, parse_opt_u32, '00')
parse_via_ffi(
  Scale::Types::U32.new(16_777_215),
  Scale::Types::OptionU32,
  parse_opt_u32,
  '01ffffff00'
)
