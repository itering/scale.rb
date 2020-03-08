# coding: utf-8

require 'scale'
require_relative './types_for_test.rb'
require 'ffi'

module Rust
  extend FFI::Library
  ffi_lib 'target/debug/libvector_ffi.' + FFI::Platform::LIBSUFFIX
  attach_function :byte_string_literal_parse, %i[pointer int], :bool
end

encoded_u64 = Scale::Types::U64.new(14_294_967_296).encode
describe do
  it 'encoding should match specification' do
    expect(encoded_u64).to eql('00e40b5403000000')
  end
end
vec = Scale::Bytes.new('0x' + encoded_u64).bytes

FFI::MemoryPointer.new(:int8, vec.size) do |vec_c|
  vec_c.write_array_of_int8 vec
  puts "vec_c: #{ vec_c }"
  puts Rust.byte_string_literal_parse(vec_c, vec_c.size)
end
