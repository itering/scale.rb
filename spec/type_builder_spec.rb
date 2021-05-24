require "scale"

describe Scale::Types do
  before(:all) { 
    Scale::TypeRegistry.instance.load
  }

  it "can create a hard coded type" do
    type = Scale::Types.get("Compact")
    expect(type).to eq(Scale::Types::Compact)

    type = Scale::Types.get("Hex")
    expect(type).to eq(Scale::Types::Hex)
  end

  # Vec
  it "can create a Vec" do
    type = Scale::Types.get("Vec<Compact>")
    expect(type).to eq(Scale::Types::Vec_Compact_)
  end

  it "can encode and decode a vec" do
    type = Scale::Types.get("Vec<Compact>")

    scale_bytes = Scale::Bytes.new("0x081501fc")
    obj = type.decode(scale_bytes)
    expect(obj.value.length).to eq(2)
    expect(obj.value).to eq([
      Scale::Types::Compact.new(69),
      Scale::Types::Compact.new(63)
    ])

    expect(obj.encode).to eq("081501fc")
  end

  # Option
  it "can create a Option" do
    type = Scale::Types.get("Option<Compact>")
    expect(type).to eq(Scale::Types::Option_Compact_)
  end

  it "can encode and decode a option" do
    type = Scale::Types.get("Option<Compact>")

    scale_bytes = Scale::Bytes.new("0x00")
    obj = type.decode(scale_bytes)
    expect(obj.value).to eq(nil)

    scale_bytes = Scale::Bytes.new("0x011501")
    obj = type.decode(scale_bytes)
    expect(obj.value).to eq(Scale::Types::Compact.new(69))

    expect(obj.encode).to eq("011501")
  end

  # Fixed array
  it "can create a fixed array" do
    type = Scale::Types.get("[Compact; 2]")
    expect(type).to eq(Scale::Types::Array_Compact_2_)
    expect(type.name).to eq("Scale::Types::Array_Compact_2_")
  end

  it "can encode and decode a fixed array" do
    type = Scale::Types.get("[Compact; 2]")

    scale_bytes = Scale::Bytes.new("0x1501fc")
    obj = type.decode(scale_bytes)
    expect(obj.value).to eq([
      Scale::Types::Compact.new(69),
      Scale::Types::Compact.new(63)
    ])

    expect(obj.encode).to eq("1501fc")
  end

  # Tuple
  it "can create a tuple" do
    type = Scale::Types.get("(Compact, U32)")
    expect(type).to eq(Scale::Types::Tuple_Compact_U32_)
  end

  it "can encode and decode a tuple" do
    type = Scale::Types.get("(Compact, U16, U8)")

    scale_bytes = Scale::Bytes.new("0x15012efb45")
    obj = type.decode(scale_bytes)
    expect(obj.value).to eq([
      Scale::Types::Compact.new(69),
      Scale::Types::U16.new(64302),
      Scale::Types::U8.new(69)
    ])

    expect(obj.encode).to eq("15012efb45")
  end

  # Struct
  it "can get a struct and then use it to decode and encode " do
    type_def = {
      "type" => "struct",
      "type_mapping" => [
        [
          "size",
          "Compact"
        ],
        [
          "balance",
          "U16"
        ],
        [
          "balance2",
          "U8"
        ]
      ]
    }
    type = Scale::Types.get(type_def)
    expect(type).to eq(Scale::Types::Struct_SizeCompact_BalanceU16_Balance2U8_)

    scale_bytes = Scale::Bytes.new("0x15012efb45")
    obj = type.decode(scale_bytes)
    expect(obj.value).to eq({
      "size" => Scale::Types::Compact.new(69),
      "balance" => Scale::Types::U16.new(64302),
      "balance2" => Scale::Types::U8.new(69)
    })

    expect(obj.encode).to eq("15012efb45")
  end

  it "should be different of two struct with different labels but same inner types" do
    type_def = {
      "type" => "struct",
      "type_mapping" => [
        [
          "size",
          "Compact"
        ],
        [
          "balance",
          "U16"
        ],
        [
          "balance2",
          "U8"
        ]
      ]
    }
    type1 = Scale::Types.get(type_def)

    type_def = {
      "type" => "struct",
      "type_mapping" => [
        [
          "abc",
          "Compact"
        ],
        [
          "balance",
          "U16"
        ],
        [
          "balance2",
          "U8"
        ]
      ]
    }
    type2 = Scale::Types.get(type_def)
    expect(type1).not_to eq(type2) 

  end

  it "should be equal of two struct with the same structure" do
    type_def = {
      "type" => "struct",
      "type_mapping" => [
        [
          "size",
          "Compact"
        ],
        [
          "balance",
          "U16"
        ],
        [
          "balance2",
          "U8"
        ]
      ]
    }
    type1 = Scale::Types.get(type_def)

    type_def = {
      "type" => "struct",
      "type_mapping" => [
        [
          "size",
          "Compact"
        ],
        [
          "balance",
          "U16"
        ],
        [
          "balance2",
          "U8"
        ]
      ]
    }
    type2 = Scale::Types.get(type_def)
    expect(type1).to eq(type2) 

  end

  # Enum
  it "can get a enum and then use it to decode and encode " do
    type_def = {
      "type" => "enum",
      "type_mapping" => [
        [
          "RingBalance",
          "Balance"
        ],
        [
          "KtonBalance",
          "Balance"
        ]
      ]
    }
    type = Scale::Types.get(type_def)
    expect(type).to eq(Scale::Types::Enum_RingBalanceU128_KtonBalanceU128_)

    type_def = {
      "type" => "enum",
      "type_mapping" => [
        [
          "eth_abc",
          "[U8; 20]"
        ],
        [
          "Tron",
          "[U8; 20]"
        ]
      ]
    }
    type = Scale::Types.get(type_def)
    expect(type).to eq(Scale::Types::Enum_EthAbcArray_U8_20__TronArray_U8_20__)
  end

  it "" do
  end
  
end
