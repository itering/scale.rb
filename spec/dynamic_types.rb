require "scale"


describe Scale::TypeRegistry do
  it "can add custom types" do
    # There is no LeasePeriod in the hard coded types
    Scale::TypeRegistry.instance.load
    expect(Scale::Types.get("Hello")).to be_nil
    expect(Scale::Types.get("World")).to be_nil

    # but exist if load types from kusama.json
    Scale::TypeRegistry.instance.load(custom_types: {
      Hello: "u8",
      World: {
        type: "struct",
        type_mapping: [
          ["total", "Compact<Balance>"],
          ["age", "u32"]
        ]
      }
    })
    expect(Scale::Types.get("Hello")).to eql(Scale::Types::U8)
    expect(Scale::Types.get("World").name.start_with?("Scale::Types::Struct_Of_Compact˂Balance˃_U32")).to eql(true)
  end

  it "can change spec_version on fly if there are more than one spec version of a spec" do
    Scale::TypeRegistry.instance.load(spec_name: "kusama")

    Scale::TypeRegistry.instance.spec_version = 1056
    expect(Scale::Types.get("Weight")).to eql(Scale::Types::U32)

    Scale::TypeRegistry.instance.spec_version = 1057
    expect(Scale::Types.get("Weight")).to eql(Scale::Types::U64)
  end
end
