# coding: utf-8

require 'scale'
require 'ffi'

module Rust
  extend FFI::Library
  ffi_lib 'target/debug/libvector_ffi.' + FFI::Platform::LIBSUFFIX
  attach_function :vector_input, %i[pointer int], :int
end

# vec = [7, 8, 9]
# vec_c = FFI::MemoryPointer.new(:int, vec.size)
# vec_c.write_array_of_int vec
# describe do
#   it 'should return 1 regardless of input' do
#     expect(Rust.vector_input(vec_c, vec.size)).to eql(1)
#   end
# end

scale_bytes = Scale::Bytes.new('0x45')
# scale_bytes = Scale::Bytes.new('0x0c003afe')
scale_bytes = Scale::Bytes.new('0x2a00')
puts scale_bytes.bytes
scale_bytes_c = FFI::MemoryPointer.new(48)
scale_bytes_c.write_array_of_int scale_bytes.bytes
Rust.vector_input(scale_bytes_c, 12)
