require "scale"
require 'pathname'

ROOT = Pathname.new File.expand_path("../../", __FILE__)

module Scale::Types
  describe Extrinsic do
    before(:all) {
      Scale::TypeRegistry.instance.load("kusama", 1045)
      hex = File.open(File.join(ROOT, "spec", "metadata", "v10", "hex")).read.strip
      scale_bytes = Scale::Bytes.new(hex)
      metadata = Scale::Types::Metadata.decode scale_bytes
      Scale::TypeRegistry.instance.metadata = metadata.value
    }

    it "can decode balance transfer payload" do

      unsigned_payload = "0xa8040600ff586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409070010a5d4e8"
      extrinsic = Extrinsic.decode(Scale::Bytes.new(unsigned_payload))
      value = extrinsic.value

      expect(value[:call_module]).to eql("balances")
      expect(value[:call_function]).to eql("transfer")

      expect(value[:params][0][:name]).to eql("dest")
      expect(value[:params][0][:type]).to eql("<T::Lookup as StaticLookup>::Source")
      expect(value[:params][0][:value]).to eql("0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409")

      expect(value[:params][1][:name]).to eql("value")
      expect(value[:params][1][:type]).to eql("Compact<T::Balance>")
      expect(value[:params][1][:value]).to eql(1_000_000_000_000)
    end

    it "can encode transfer payload" do
      value = {
        call_index: "0600",
        call_module: "balances",
        call_function: "transfer",
        params: [
          {
            name: "dest",
            type: "<T::Lookup as StaticLookup>::Source",
            value: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409"
          },
          {
            name: "value",
            type: "Compact<T::Balance>",
            value: 1_000_000_000_000
          }
        ]
      }
      extrinsic = Extrinsic.new(value)
      expect(extrinsic.encode).to eql("0xa8040600ff586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409070010a5d4e8")
    end

    # it "can encode to transfer payload 2" do
      # client = SubstrateClient.new("wss://cc3-5.kusama.network/")
      # client.init

      # call_params = { dest: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409", value: 1_000_000_000_000 }
      # payload = client.compose_call("balances", "transfer", call_params)
      # expect(payload).to eql("0xa8040400ff586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409070010a5d4e8")
    # end
  end

end
