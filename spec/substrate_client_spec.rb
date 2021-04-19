require "scale"
RSpec.describe SubstrateClient do
  before(:all) {
    @client = SubstrateClient.new("wss://kusama-rpc.polkadot.io/")
  }

  # {
  #   "name": "TotalIssuance",
  #   "type": {
  #     "Plain": "Balance"
  #   },
  #   ...
  # },
  it "can generate correct storage key for plain type" do
    storage_key = SubstrateClient::Helper.generate_storage_key("Balances", "TotalIssuance", nil, nil, nil, 11)
    expect(storage_key).to eq("0xc2261276cc9d1f8598ea4b6a74b15c2f57c875e4cff74148e4628f264b974c80")
  end

  # {
  #   "name": "Account",
  #   "type": {
  #     "Map": {
  #       "hasher": "Blake2_128Concat",
  #       "key": "AccountId",
  #       "value": "AccountInfo<Index, AccountData>",
  #       "linked": false
  #     }
  #   },
  #   ...
  # },
  it "can generate correct storage key for map type" do
    storage_key = SubstrateClient::Helper.generate_storage_key("System", "Account", ["0x30599dba50b5f3ba0b36f856a761eb3c0aee61e830d4beb448ef94b6ad92be39"], "Blake2_128Concat", nil, 11)
    expect(storage_key).to eq("0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9b006ad531e054edf786780ebfc7ac78030599dba50b5f3ba0b36f856a761eb3c0aee61e830d4beb448ef94b6ad92be39")
  end


  # {
  #   "name": "AuthoredBlocks",
  #   "type": {
  #     "DoubleMap": {
  #       "hasher": "Twox64Concat",
  #       "key1": "SessionIndex",
  #       "key2": "ValidatorId",
  #       "value": "U32",
  #       "key2Hasher": "Twox64Concat"
  #     }
  #   },
  # },
  it "can generate correct storage key for double map type" do
    storage_key = SubstrateClient::Helper.generate_storage_key("ImOnline", "AuthoredBlocks", ["0x020b0000", "0x749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757"], "Twox64Concat", "Twox64Concat", 11)
    expect(storage_key).to eq("0x2b06af9719ac64d755623cda8ddd9b94b1c371ded9e9c565e89ba783c4d5f5f93b6390c9afa3500d020b0000b0f0b3ac307cd751749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757")
  end

  it "can encode balances transfer payload" do
    payload = @client.compose_call(
      "balances",
      "transfer",
      { dest: { account_id: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409", account_length: "0xff" }, value: 1_000_000_000_000 }
    )
    expect(payload).to eql("0xa8040500ff586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409070010a5d4e8")
  end

  it "can build storage_hash from storage_data correctly" do
    storage = @client.state_getStorage("0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7", "0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    storage_hash_calc = @client.generate_storage_hash_from_data(storage)

    storage_hash = @client.state_getStorageHash("0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7", "0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")

    expect(storage_hash).to eq(storage_hash_calc)
  end

  it "can get block by hash" do 
    block = @client.chain_getBlock("0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    expect(block.keys).to eq(["block", "justifications"])
  end

  it "can get block hash by id" do
    block_hash = @client.chain_getBlockHash(4383624)
    expect(block_hash).to eq("0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
  end

  it "can get finalised head" do
    head = @client.chain_getFinalizedHead
    expect(head).not_to be_nil
    expect(head).to be_a(String)
    expect(head.length).to eq(66)
  end

  it "can get header by block hash" do
    header = @client.chain_getHeader

    expect(header).not_to be_nil
    expect(header.keys).to eq(%w[digest extrinsicsRoot number parentHash stateRoot])
  end

  it "can call chain_getRuntimeVersion" do
    runtime_version = @client.chain_getRuntimeVersion
    expect(runtime_version).not_to be_nil

    runtime_version = @client.chain_getRuntimeVersion("0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    expect(runtime_version).not_to be_nil
    expect(runtime_version.keys).to include(*%w[apis authoringVersion implName implVersion specName specVersion transactionVersion])
  end

  it "can call state_getMetadata" do
    metadata = @client.state_getMetadata
    expect(metadata).not_to be_nil
    metadata = @client.state_getMetadata("0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    expect(metadata).not_to be_nil
  end

  it "can call state_getStorageSize" do
    size = @client.state_getStorageSize("0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7", "0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    expect(size).to be_instance_of Integer
  end

  it "can call state_getKeys" do
    keys = @client.state_getKeys("0x26aa394eea5630e07c48ae0c9558cef7") # System
    expect(keys).to be_instance_of Array

    keys = @client.state_getKeys("0x26aa394eea5630e07c48ae0c9558cef7", "0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37") # System
    expect(keys.length).to eq(24860)
  end

  it "can call state_getReadProof" do
    read_proof = @client.state_getReadProof(["0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7"], "0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    expect(read_proof["at"]).to eq("0x860e0ed04bd1b2a1efa70c9db13cc73f830d7e14204680316db52f05fd91ba37")
    expect(read_proof["proof"].sort).to eq([
      "0x5f00d41e5e16056765bc8461851072c9d71d041c00000000000000482d7c09000000000200000001000000000000000000000000000200000002000000000460be3b72c1a97581bc12546fcd4b87fc15108fc0c73dfc4d753ab1c50d52ae2d000002000000020260be3b72c1a97581bc12546fcd4b87fc15108fc0c73dfc4d753ab1c50d52ae2de44a51a46974124ce3c64f3bf03aff8515ed95b56773dc10ead861c24e1db451f28190eb2697000000000000000000000000020000000d06a4d12e7b0000000000000000000000000000020000000204284af42f982d76c7a3bf90ffee5b2269819160c7e6efd79da6aa1b902cea17576ab4cb1e000000000000000000000000000002000000000088a6610b00000000000000",
      "0x80490c80d64cb3ca72e1836da35a1a25368abbd93b0498130c8a64bf8e4fc87cf12721ef8061c1216c36609bb3dd8e924fcd2e70615d5aba379dc98063b8d88d65f456fe1980567da13f047da24bbf2c7c3549b9711e90285ab88b7498689e2bd4ca7ba16db98000b90a9bf0310f385e32e4c4782bcf11486edc30647305ff09ca723b4f4a4da48068effda157d7c538bf72d174addf2f9a3919fea39629e6ef3f7343ba91d2198d",
      "0x80ffff806ceec8a1773cce17b9f71f8ac1e6c7cabd80a39886e1a4131f81fbdc7d028c1b80c272dbb9751b51791d7814f3fb018e644720e5e7870675265e4d10a698ad2248808bbdb68b21b5c6f1bf2a1efd5c25e0601eb0d4c53ffd6710d2c3e0117796796a8040c30fdd0a8e6d8b86ad2cdc01e373d2db92aabf636c2f61c2bce936cccbd50680331b4a4cf89aba77fefe742eb6d29eaf82245f32514182be6000a48ae63c88aa80e98b34a3dca8f5e2e52b95ba9ee873bb1c0ced77d9e26ec66c2f5d948af23188800eb754c27d6302344f80fc4f785eae09c7c6acf58ee0ebddbd2f1755eb37a7de801f95143f753ca72027b1cc22a192f3ad723e50f6a8d829d33f16ab86edb436588073006a6e2b67ea2bf54b9470a24efcb8281f5c430427adf65d09515297fe60cd80218f9f57770b9684f83e7b85f9fb5c2e413f5035aea9e42f464112150782c85f80aa6480ef61591505150aa43e08242ab5090001e07d697d221173ba715307caa280ceb99919026603d1b3e766b0a8fa14a9b95372ed2012116ccef79620a1e12ba480993797741dbe93f909cc6c2d8c1659c1e8e39f2cbd9ff5a56932446463854ca880cfec1a3f89f21935f38bdd35417555508dc7ea3dfbe86344223dab804631b91f801445b1bc4c1b47f60f2fdf3cb3165d2065614c6dc5306c7484300bbd1c44f83980238619b1a6a27c34c90514a38cdeea00016037b274c9a30d0f3184547ac8310e",
      "0x9eaa394eea5630e07c48ae0c9558cef7098f585f0a98fdbe9ce6c55837576c60c7af38501007000000807fa42d592e63baded09be78241a2f59bcc7a086f62132c8e893a6df8a4ee80bc8024a178ae32008493af6d8bbe69591e95686153ed0665c573c2e131ccba334c2d80f396a256a26d97da8d35bf298a8de6b3e036c28fe4ce34671ab956b461584bef80d6bbf1e29794a140b4b481a1a00c5fdb11806e050d891cc35440ffd8a6dd678780dde77fd1da392f483ba5a0331395120e4ccddc8c4ea87995397fe1b2e3790dcd6c5f09cce9c888469bb1a0dceaa129672ef824a11f186b7573616d61"
    ])
  end

  it "can call system_version" do
    system_version = @client.system_version()
    expect(system_version).to be_instance_of(String)
  end

  it "can call system_properties" do
    system_properties = @client.system_properties
    expect(system_properties.keys).to contain_exactly("ss58Format", "tokenDecimals", "tokenSymbol")
  end

  it "can call system_nodeRoles" do
    system_node_roles = @client.system_nodeRoles
    expect(system_node_roles).to eq(["Full"])
  end

  it "can call system_chain" do
    system_chain = @client.system_chain
    expect(system_chain).to eq("Kusama")
  end

  it "can call system_accountNextIndex" do
    result = @client.system_accountNextIndex("EQBwtmKWCyRrQ8yGWg7LkB8p7hpEKXZz4qUg9WR8hZmieCM")
    expect(result).to be_a(Integer)
  end

  it "can call system_localListenAddresses" do
    result = @client.system_localListenAddresses
    expect(result).to be_a(Array)
  end

  it "can call grandpa_roundState" do
    result = @client.grandpa_roundState
    expect(result).to be_a(Hash)
    expect(result.keys).to contain_exactly("background", "best", "setId")
  end

  it "can get decoded storage" do 
    account = @client.get_storage "System", "Account", ["0x50be873393f9e3f5705d8b573729cd35b080e5f9029534e8b848371a9cdecc1e"], "0xedf6ff93fb6dd1c00b96dafb576e01975e85710ff3b0eea7244e576579f28388"

    expect_result = {"c"=>2, "data"=>{"feeFrozen"=>499192308000, "free"=>378566339746251, "miscFrozen"=>499192308000, "reserved"=>0}, "nonce"=>0}
    expect(account.to_human).to eq(expect_result)
  end
end
