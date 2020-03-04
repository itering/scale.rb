require "scale"

module Scale
  module Types

    describe Set do
      it "should work right" do
        o = WithdrawReasons.decode Scale::Bytes.new("0x0100000000000000")
        expect(o.value).to eql(["TransactionPayment"])
        expect(o.encode).to eql("0100000000000000")

        o = WithdrawReasons.decode Scale::Bytes.new("0x0300000000000000")
        expect(o.value).to eql(["TransactionPayment", "Transfer"])
        expect(o.encode).to eql("0300000000000000")

        o = WithdrawReasons.decode Scale::Bytes.new("0x1600000000000000")
        expect(o.value).to eql(["Transfer", "Reserve", "Tip"])
        expect(o.encode).to eql("1600000000000000")
      end
    end

  end
end
