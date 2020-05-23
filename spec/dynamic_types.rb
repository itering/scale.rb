require "scale"


describe Scale::TypeRegistry do
  it "can create new type from json files" do
    # There is no LeasePeriod in the hard coded types
    Scale::TypeRegistry.instance.load
    expect(Scale::Types.get("IdentityInfo")).to be_nil

    # but exist if load types from kusama.json
    Scale::TypeRegistry.instance.load("kusama", 1054)
    expect(Scale::Types.get("IdentityInfo")).to be
  end
end
