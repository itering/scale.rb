require "scale"

describe Scale::Types do
  before(:all) { 
    Scale::TypeRegistry.instance.load
  }

  it "can create a hard coded type" do
    type = Scale::Types.build("Compact")
    expect(type).to eq(Scale::Types::Compact)

    type = Scale::Types.build("Hex")
    expect(type).to eq(Scale::Types::Hex)
  end

  # Vec
  it "can create a Vec" do
    type = Scale::Types.build("Vec<Compact>")
    expect(type).to eq(Scale::Types::VecCompact)
  end

  it "can encode and decode a vec" do
    type = Scale::Types.build("Vec<Compact>")

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
    type = Scale::Types.build("Option<Compact>")
    expect(type).to eq(Scale::Types::OptionCompact)
  end

  it "can encode and decode a option" do
    type = Scale::Types.build("Option<Compact>")

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
    type = Scale::Types.build("[Compact; 2]")
    expect(type).to eq(Scale::Types::ArrayCompact)
  end

  it "can encode and decode a fixed array" do
    type = Scale::Types.build("[Compact; 2]")

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
    type = Scale::Types.build("(Compact, U32)")
    expect(type).to eq(Scale::Types::TupleCompactU32)
  end

  it "can encode and decode a tuple" do
    type = Scale::Types.build("(Compact, U16, U8)")

    scale_bytes = Scale::Bytes.new("0x15012efb45")
    obj = type.decode(scale_bytes)
    puts obj.value
    expect(obj.value).to eq([
      Scale::Types::Compact.new(69),
      Scale::Types::U16.new(64302),
      Scale::Types::U8.new(69)
    ])

    expect(obj.encode).to eq("15012efb45")
  end

  # Struct
end
