# coding: utf-8

require 'scale'
require_relative './types_for_test.rb'
require 'ffi'

module Rust
  extend FFI::Library
  ffi_lib 'target/debug/libvector_ffi.' + FFI::Platform::LIBSUFFIX
  attach_function :byte_string_literal_parse_u64, %i[pointer int uint64], :bool
end

parse_u64 = proc { |vec_c, value|
  Rust.byte_string_literal_parse_u64(vec_c, vec_c.size, value)
}

def parse_via_ffi(value, encoding, ffi_function, expectation)
  encoded = encoding.new(value).encode
  puts encoded
  describe do
    it 'encoding should match specification' do
      expect(encoded).to eql(expectation)
    end
  end
  vec = Scale::Bytes.new('0x' + encoded).bytes
  puts vec

  FFI::MemoryPointer.new(:int8, vec.size) do |vec_c|
    vec_c.write_array_of_int8 vec
    puts "vec_c: #{vec_c}"
    ffi_success = ffi_function.call(vec_c, value)
    describe do
      it 'Rust implementation should decode to expected value' do
        expect(ffi_success).to eql(true)
      end
    end
  end
end

parse_via_ffi(14_294_967_296, Scale::Types::U64, parse_u64, '00e40b5403000000')
