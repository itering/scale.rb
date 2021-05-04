require "scale"
require_relative "./ffi_helper.rb"

def assert_map(module_name, storage_name, param, param_hasher)
  storage_key_ruby = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param], param_hasher)[2..]

  param = u8_array_to_pointer param.encode.hex_to_bytes
  storage_key_rust = Rust.get_storage_key_for_map(module_name, storage_name, param, param.size, param_hasher)

  expect(storage_key_ruby).to eq(storage_key_rust)
end

def assert_double_map(module_name, storage_name, param1, param1_hasher, param2, param2_hasher)
  storage_key_ruby = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param1, param2], param1_hasher, param2_hasher)[2..]

  param1 = u8_array_to_pointer param1.encode.hex_to_bytes
  param2 = u8_array_to_pointer param2.encode.hex_to_bytes
  storage_key_rust = Rust.get_storage_key_for_double_map(
    module_name, storage_name, 
    param1, param1.size, param1_hasher,
    param2, param2.size, param2_hasher
  )

  expect(storage_key_ruby).to eq(storage_key_rust)
end

describe SubstrateClient::Helper do
  before(:all) { 
    Scale::TypeRegistry.instance.load
  }

  it "can generate correct storage_key for storage value" do
    module_name = 'Sudo'
    storage_name = 'Key'
    storage_key_ruby = SubstrateClient::Helper.generate_storage_key(module_name, storage_name)[2..]
    storage_key_rust = Rust.get_storage_key_for_value(module_name, storage_name)

    expect(storage_key_ruby).to eq(storage_key_rust)
  end

  it "can generate correct storage_key for storage map blake2_128_concat" do
    module_name = 'ModuleAbc'
    storage_name = 'Map1'
    
    # 1
    param = Scale::Types::U32.new(1)
    assert_map(module_name, storage_name, param, 'blake2_128_concat')

    # 2
    param = Scale::Types::GenericMultiAddress.decode Scale::Bytes.new("0x0467f89207abe6e1b093befd84a48f033137659292")
    assert_map(module_name, storage_name, param, 'blake2_128_concat')
  end

  it "can generate correct storage_key for storage map twox64_concat" do
    module_name = 'ModuleAbc'
    storage_name = 'Map2'

    # 1
    param = Scale::Types::U32.new(1)
    assert_map(module_name, storage_name, param, 'twox64_concat')

    # 2
    scale_bytes = Scale::Bytes.new("0x0100000045000045")
    param = Scale::Types::Student.decode scale_bytes
    assert_map(module_name, storage_name, param, 'twox64_concat')
  end

  it "can generate correct storage_key for storage map identity" do
    module_name = 'Hello'
    storage_name = 'World'

    param = Scale::Types::U32.new(1)
    assert_map(module_name, storage_name, param, 'identity')
  end

  it "can generate a correct storage_key for storage doublemap" do
    module_name = 'ModuleAbc'
    storage_name = 'DoubleMap1'
    param1 = Scale::Types::U32.new(1)
    param2 = Scale::Types::U32.new(2)

    # 1
    assert_double_map(
      module_name, storage_name,
      param1, 'blake2_128_concat',
      param2, 'blake2_128_concat',
    )

    # 2
    storage_name = 'DoubleMap2'
    assert_double_map(
      module_name, storage_name,
      param1, 'blake2_128_concat',
      param2, 'twox64_concat',
    )

    # 3
    storage_name = 'LaLaLa'
    param1 = Scale::Types::IntOrBool.decode Scale::Bytes.new("0x0101")
    param2 = Scale::Types::Compact.new(2)
    assert_double_map(
      module_name, storage_name,
      param1, 'twox64_concat',
      param2, 'identity',
    )
  end
end
