require "scale"

describe Scale::Types do
  before(:all) { Scale::TypeRegistry.instance.load("default") }

  it "can correctly encode and decode U8" do
    scale_bytes = Scale::Bytes.new("0x45")
    o = Scale::Types::U8.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("45")
  end

  it "can correctly encode and decode U16" do
    scale_bytes = Scale::Bytes.new("0x2efb")
    o = Scale::Types::U16.decode scale_bytes
    expect(o.value).to eql(64302)
    expect(o.encode).to eql("2efb")
  end

  it "can correctly encode and decode I16" do
    scale_bytes = Scale::Bytes.new("0x2efb")
    o = Scale::Types::I16.decode scale_bytes
    expect(o.value).to eql(-1234)
    expect(o.encode).to eql("2efb")
  end

end

