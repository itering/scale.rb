require "scale"

describe Scale::Types::FixedWidthUInt do
  it "should encode u8 right" do
    scale_bytes = Scale::Bytes.new("0x45")
    o = Scale::Types::U8.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("45")
  end

  it "should encode u16 right" do
    scale_bytes = Scale::Bytes.new("0x2a00")
    o = Scale::Types::U16.decode scale_bytes
    expect(o.value).to eql(42)
    expect(o.encode).to eql("2a00")
  end

  it "should encode u32 right" do
    scale_bytes = Scale::Bytes.new("0xffffff00")
    o = Scale::Types::U32.decode scale_bytes
    expect(o.value).to eql(16777215)
    expect(o.encode).to eql("ffffff00")
  end

  it "should encode u64 right" do
    scale_bytes = Scale::Bytes.new("0x00e40b5403000000")
    o = Scale::Types::U64.decode scale_bytes
    expect(o.value).to eql(14294967296)
    expect(o.encode).to eql("00e40b5403000000")
  end

  it "should encode u128 right" do
    scale_bytes = Scale::Bytes.new("0x0bfeffffffffffff0000000000000000")
    o = Scale::Types::U128.decode scale_bytes
    expect(o.value).to eql(18446744073709551115)
    expect(o.encode).to eql("0bfeffffffffffff0000000000000000")
  end
end

describe Scale::Types::Bool do
  it "should encode bool right" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::Bool.decode scale_bytes
    expect(o.value).to eql(false)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01")
    o = Scale::Types::Bool.decode scale_bytes
    expect(o.value).to eql(true)
    expect(o.encode).to eql("01")
  end
end

describe Scale::Types::Compact do
  it "should encode single-byte mode compact right" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(0)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x04")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1)
    expect(o.encode).to eql("04")

    scale_bytes = Scale::Bytes.new("0xa8")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(42)
    expect(o.encode).to eql("a8")

    scale_bytes = Scale::Bytes.new("0xfc")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(63)
    expect(o.encode).to eql("fc")
  end

  it "should encode two-byte mode compact right" do
    scale_bytes = Scale::Bytes.new("0x1501")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("1501")
  end

  it "should encode four-byte mode compact right" do
    scale_bytes = Scale::Bytes.new("0xfeffffff")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1073741823)
    expect(o.encode).to eql("feffffff")
  end

  it "should encode big-integer mode compact right" do
    scale_bytes = Scale::Bytes.new("0x0300000040")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1073741824)
    expect(o.encode).to eql("0300000040")
  end
end

describe Scale::Types::Option do
  it "should encode option bool right" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::OptionBool.decode scale_bytes
    expect(o.value).to eql(nil)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01")
    o = Scale::Types::OptionBool.decode scale_bytes
    expect(o.value).to eql(false)
    expect(o.encode).to eql("01")

    scale_bytes = Scale::Bytes.new("0x02")
    o = Scale::Types::OptionBool.decode scale_bytes
    expect(o.value).to eql(true)
    expect(o.encode).to eql("02")
  end

  it "should encode option u32 right" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::OptionU32.decode scale_bytes
    expect(o.value).to eql(nil)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01ffffff00")
    o = Scale::Types::OptionU32.decode scale_bytes
    expect(o.value.value).to eql(16777215)
    expect(o.encode).to eql("01ffffff00")
  end
end

describe Scale::Types::Vector do
  it "should encode vector u8 right" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    o = Scale::Types::VectorU8.decode scale_bytes
    expect(o.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("0c003afe")
  end

  it "should encode vector u8 right" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    o = type("Vec<U8>").decode scale_bytes
    expect(o.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("0c003afe")
  end
end

describe Scale::Types::Struct do
  it "should encode student right" do
    scale_bytes = Scale::Bytes.new("0x0100000045000045")
    o = Scale::Types::Student.decode scale_bytes

    [
      [o.age, Scale::Types::U32],
      [o.grade, Scale::Types::U8],
      [o.courses_number, Scale::Types::OptionU32],
      [o.int_or_bool, Scale::Types::IntOrBool]
    ]
      .map { |(actual, expectation)| expect(actual.class).to eql(expectation) }

    [
      [o.age, 1],
      [o.grade, 69],
      [o.courses_number, nil],
      [o.int_or_bool.value, 69]
    ]
      .map { |(actual, expectation)| expect(actual.value).to eql(expectation) }

    expect(o.encode).to eql("0100000045000045")
  end
end

describe Scale::Types::Enum do
  it "should encode IntOrBool right" do
    scale_bytes = Scale::Bytes.new("0x0101")
    o = Scale::Types::IntOrBool.decode scale_bytes
    expect(o.encode).to eql("0101")
    expect(o.value.value).to eql(true)

    scale_bytes = Scale::Bytes.new("0x002a")
    o = Scale::Types::IntOrBool.decode scale_bytes
    expect(o.encode).to eql("002a")
    expect(o.value.value).to eql(42)
  end
end
