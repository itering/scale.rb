require "scale"

describe Scale::Types::Student do
  it "should decode from a scale hex string" do
    # 0x 01000000 45 00 0045
    scale_bytes = Scale::Bytes.new("0x0100000045000045")
    s1 = Scale::Types::Student.decode scale_bytes
    expect(s1.age.class).to eql(Scale::Types::U32)
    expect(s1.grade.class).to eql(Scale::Types::U8)
    expect(s1.courses_number.class).to eql(Scale::Types::OptionU32)
    expect(s1.int_or_bool.class).to eql(Scale::Types::IntOrBool)
    expect(s1.age.value).to eql(1)
    expect(s1.grade.value).to eql(69)
    expect(s1.courses_number.value).to eql(nil)
    expect(s1.int_or_bool.value.value).to eql(69)

    # 0x 01000000 45 0145000000 0045
    scale_bytes = Scale::Bytes.new("0x010000004501450000000045")
    s2 = Scale::Types::Student.decode scale_bytes
    expect(s2.age.value).to eql(1)
    expect(s2.grade.value).to eql(69)
    expect(s2.courses_number.value.value).to eql(69)
    expect(s2.int_or_bool.value.value).to eql(69)

    # 0x 01000000 45 00 0101
    scale_bytes = Scale::Bytes.new("0x0100000045000101")
    s3 = Scale::Types::Student.decode scale_bytes
    expect(s3.age.value).to eql(1)
    expect(s3.grade.value).to eql(69)
    expect(s3.courses_number.value).to eql(nil)
    expect(s3.int_or_bool.value.value).to eql(true)
  end
end

describe Scale::Types::Compact do
  it "should decode from a scale hex string" do 
    # 1 bytes mod
    scale_bytes = Scale::Bytes.new("0x00")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(0)

    scale_bytes = Scale::Bytes.new("0x04")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(1)

    scale_bytes = Scale::Bytes.new("0xa8")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(42)

    scale_bytes = Scale::Bytes.new("0x0c")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(3)

    # 2 bytes mod
    scale_bytes = Scale::Bytes.new("0x1501")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(69)

    scale_bytes = Scale::Bytes.new("0xf914")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(1342)

    # 4 bytes mod
    scale_bytes = Scale::Bytes.new("0x02000100")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(16384)

    scale_bytes = Scale::Bytes.new("0xfeffffff")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(1073741823)

    # big integer mode
    scale_bytes = Scale::Bytes.new("0x0300000040")
    c = Scale::Types::Compact.decode scale_bytes
    expect(c.value).to eql(1073741824)
  end
end

describe Scale::Types::VecU8 do
  it "should decode from a scale hex string" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    v = Scale::Types::VecU8.decode scale_bytes
    expect(v.value.length).to eql(3)
    expect(v.value[0].value).to eql(0)
    expect(v.value[1].value).to eql(58)
    expect(v.value[2].value).to eql(254)
  end
end

# name = "Person"
# klass = Class.new do
# end
# klass.send(:include, Scale::Types::Struct)
# klass.send(:items, proposal: 'Scale::Types::Hex')
# Object.const_set name, klass
