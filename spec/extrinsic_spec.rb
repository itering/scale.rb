require "scale"

ROOT = Pathname.new File.expand_path("../../", __FILE__)

module Scale::Types
  describe Extrinsic do
    before(:all) { Scale::TypeRegistry.instance.load("kusama", 1045) }

    let(:metadata) {
      hex = File.open(File.join(ROOT, "spec", "metadata", "v10", "hex")).read.strip
      scale_bytes = Scale::Bytes.new(hex)
      Scale::Types::Metadata.decode scale_bytes
    }

    it "can decode balance transfer payload" do
      unsigned_payload = "0xa8040600ff586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409070010a5d4e8"
      extrinsic = Extrinsic.decode(Scale::Bytes.new(unsigned_payload), metadata)

      expect(extrinsic[:call_module]).to eql("balances")
      expect(extrinsic[:call_function]).to eql("transfer")

      expect(extrinsic[:params][0][:name]).to eql("dest")
      expect(extrinsic[:params][0][:type]).to eql("Scale::Types::RawAddress")
      expect(extrinsic[:params][0][:value]).to eql("0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409")

      expect(extrinsic[:params][1][:name]).to eql("value")
      expect(extrinsic[:params][1][:type]).to eql("Scale::Types::Compact")
      expect(extrinsic[:params][1][:value]).to eql(1000000000000)
    end
  end
end
