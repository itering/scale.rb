# frozen_string_literal: true

require "scale"
require_relative "./types.rb"
require "ffi"

module Rust
  extend FFI::Library
  ffi_lib "target/debug/libscale_ffi." + FFI::Platform::LIBSUFFIX
  attach_function :parse_u64, %i[pointer int uint64], :void
  attach_function :parse_u32, %i[pointer int uint32], :void
  attach_function :parse_u8, %i[pointer int uint8], :void
  attach_function :parse_bool, %i[pointer int bool], :void
  attach_function :parse_opt_u32, %i[pointer int uint32 bool], :void
  attach_function :parse_opt_bool, %i[pointer int bool bool], :void

  attach_function :get_storage_key_for_value, %i[string string], :string
  attach_function :get_storage_key_for_map, %i[string string pointer int string], :string
  attach_function :get_storage_key_for_double_map, %i[string string pointer int string pointer int string], :string
end

def parse_type(key)
  {
    Scale::Types::U64 => proc { |vec, val| Rust.parse_u64(vec, vec.size, val) },

    Scale::Types::U32 => proc { |vec, val| Rust.parse_u32(vec, vec.size, val) },

    Scale::Types::U8 => proc { |vec, val| Rust.parse_u8(vec, vec.size, val) },

    Scale::Types::Bool => proc { |vec, val| Rust.parse_bool(vec, vec.size, val) },

    Scale::Types::OptionU32 => proc { |vec, val|
      if val.nil?
        Rust.parse_opt_u32(vec, vec.size, 0, false)
      else
        Rust.parse_opt_u32(vec, vec.size, val.value, true)
      end
    },

    Scale::Types::OptionBool => proc { |vec, val|
      if val.nil?
        Rust.parse_opt_bool(vec, vec.size, false, false)
      else
        puts "value: #{val}"
        Rust.parse_opt_bool(vec, vec.size, val, true)
      end
    }
  }[key]
end

def check_against_specification(encoded, expectation)
  describe do
    it "encoding should match specification" do
      expect(encoded).to eql(expectation)
    end
  end
end

def parse_via_ffi(value, encoding)
  encoded = encoding.new(value).encode
  # check_against_specification(encoded, expectation)
  puts "\nencoded: #{encoded}, value: #{value}, type: #{encoding}"
  vec = Scale::Bytes.new("0x" + encoded).bytes

  vec_c = FFI::MemoryPointer.new(:int8, vec.size)
  vec_c.write_array_of_int8 vec
  parse_type(encoding).call(vec_c, value)
end

def u8_array_to_pointer(arr)
  pointer = FFI::MemoryPointer.new(:int8, arr.size)
  pointer.write_array_of_int8 arr
  pointer
end
# everything beyond this point should ultimately be moved to types_spec.rb or
# removed
