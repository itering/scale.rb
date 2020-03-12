require "scale"

describe Scale::Types do
  it "can list all types according to the chain spec" do
    list_default = Scale::Types.list
    puts list_default
    # list_kusama = Scale::Types.list("kusama")
    # p list_kusama
  end
end
