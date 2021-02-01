require "scale"
require_relative "./ffi_helper.rb"

def assert_storage_key_for_value(module_name, storage_name, expectation)
  m = u8_array_to_pointer module_name.bytes
  s = u8_array_to_pointer storage_name.bytes
  e = u8_array_to_pointer expectation.hex_to_bytes
  Rust.assert_storage_key_for_value(m, m.size, s, s.size, e, e.size)
end

def assert_storage_key_for_map_black2128concat(module_name, storage_name, param, expectation)
  m = u8_array_to_pointer module_name.bytes
  s = u8_array_to_pointer storage_name.bytes
  p = u8_array_to_pointer param.encode.hex_to_bytes
  e = u8_array_to_pointer expectation.hex_to_bytes
  Rust.assert_storage_key_for_map_black2128concat(
    m, m.size, 
    s, s.size, 
    p, p.size, 
    e, e.size
  )
end

describe SubstrateClient::Helper do
  it "can generate correct storage_key for storage value" do
    module_name = 'Sudo'
    storage_name = 'Key'
    storage_key = SubstrateClient::Helper.generate_storage_key(module_name, storage_name)

    assert_storage_key_for_value(module_name, storage_name, storage_key)
  end

  it "can generate a correct storage_key for storage map" do
    module_name = 'ModuleAbc'
    storage_name = 'Map1'
    param = Scale::Types::U32.new(1)

    storage_key = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param], 'blake2_128_concat')
    expect(storage_key).to eq("0x4ee617ba653a1b87095c394f5d41128328853a72189ae4f290a9869a054e225ad82c12285b5d4551f88e8f6e7eb52b8101000000")
    # assert_storage_key_for_map_black2128concat(module_name, storage_name, param, storage_key)

    storage_name = 'Map2'
    storage_key = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param], 'twox64_concat')
    expect(storage_key).to eq("0x4ee617ba653a1b87095c394f5d411283a4a396b3ec8979c619cf216662faa9915153cb1f00942ff401000000")

    storage_name = 'Map3'
    storage_key = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param], 'identity')
    expect(storage_key).to eq("0x4ee617ba653a1b87095c394f5d4112834f13c9117b595c775448f894b5b0516c01000000")
  end

  it "can generate a correct storage_key for storage doublemap" do
    module_name = 'ModuleAbc'
    storage_name = 'DoubleMap1'
    param1 = Scale::Types::U32.new(1)
    param2 = Scale::Types::U32.new(2)

    storage_key = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param1, param2], 'blake2_128_concat', 'blake2_128_concat')
    expect(storage_key).to eq("0x4ee617ba653a1b87095c394f5d411283c63c595452a3c75489ef352677ad51fad82c12285b5d4551f88e8f6e7eb52b8101000000754faa9acf0378f8c3543d9f132d85bc02000000")

    storage_name = 'DoubleMap2'
    storage_key = SubstrateClient::Helper.generate_storage_key(module_name, storage_name, [param1, param2], 'blake2_128_concat', 'twox64_concat')
    expect(storage_key).to eq("0x4ee617ba653a1b87095c394f5d411283fdf2e24b59506516f72546464dd82f88d82c12285b5d4551f88e8f6e7eb52b81010000009eb2dcce60f37a2702000000")
  end
end
