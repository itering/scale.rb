require "scale"

describe Scale::Types::U8 do
  it "should work right" do
    scale_bytes = Scale::Bytes.new("0x45")
    o = Scale::Types::U8.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("45")
  end
end

describe Scale::Types::U16 do
  it "should work right" do
    scale_bytes = Scale::Bytes.new("0x2a00")
    o = Scale::Types::U16.decode scale_bytes
    expect(o.value).to eql(42)
    expect(o.encode).to eql("2a00")
  end
end

describe Scale::Types::U32 do
  it "should work right" do
    scale_bytes = Scale::Bytes.new("0xffffff00")
    o = Scale::Types::U32.decode scale_bytes
    expect(o.value).to eql(16777215)
    expect(o.encode).to eql("ffffff00")
  end
end

describe Scale::Types::U64 do
  it "should work right" do
    scale_bytes = Scale::Bytes.new("0x00e40b5403000000")
    o = Scale::Types::U64.decode scale_bytes
    expect(o.value).to eql(14294967296)
    expect(o.encode).to eql("00e40b5403000000")
  end
end

describe Scale::Types::U128 do
  it "should work right" do
    scale_bytes = Scale::Bytes.new("0x0bfeffffffffffff0000000000000000")
    o = Scale::Types::U128.decode scale_bytes
    expect(o.value).to eql(18446744073709551115)
    expect(o.encode).to eql("0bfeffffffffffff0000000000000000")
  end
end

describe Scale::Types::Bool do
  it "should work right" do
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
  it "single-byte mode compact should work right" do
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

  it "two-byte mode compact should work right" do
    scale_bytes = Scale::Bytes.new("0x1501")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("1501")
  end

  it "four-byte mode compact should work right" do
    scale_bytes = Scale::Bytes.new("0xfeffffff")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1073741823)
    expect(o.encode).to eql("feffffff")
  end

  it "big-integer mode compact should work right" do
    scale_bytes = Scale::Bytes.new("0x0300000040")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1073741824)
    expect(o.encode).to eql("0300000040")
  end
end

describe Scale::Types::Option do
  it "option bool should work right" do
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

  it "option u32 should work right" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::OptionU32.decode scale_bytes
    expect(o.value).to eql(nil)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01ffffff00")
    o = Scale::Types::OptionU32.decode scale_bytes
    expect(o.value.value).to eql(16777215)
    expect(o.encode).to eql("01ffffff00")
  end

  it "can be construct form type string" do
    scale_bytes = Scale::Bytes.new("0x01ffffff00")
    type = type_of("Option<U32>")
    o = type.decode scale_bytes
    expect(o.value.value).to eql(16777215)
    expect(o.encode).to eql("01ffffff00")

    scale_bytes = Scale::Bytes.new("0x010c003afe")
    type = type_of("Option<Vec<U8>>")
    o = type.decode scale_bytes
    expect(o.value.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("010c003afe")

    scale_bytes = Scale::Bytes.new("0x0c0100013a01fe")
    type = type_of("Vec<Option<U8>>")
    o = type.decode scale_bytes
    expect(o.value.map do |e| e.value.value end).to eql([0, 58, 254])
    expect(o.encode).to eql("0c0100013a01fe")
  end
end

describe Scale::Types::Vec do
  it "vector u8 should work right" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    o = Scale::Types::VecU8.decode scale_bytes
    expect(o.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("0c003afe")
  end

  it "vector u8 should work right" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    o = type_of("Vec<U8>").decode scale_bytes
    expect(o.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("0c003afe")
  end
end

describe Scale::Types::Struct do
  it "student should work right" do
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
  it "IntOrBool should work right" do
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
