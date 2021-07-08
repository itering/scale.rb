client = SubstrateClient.new "wss://pangolin-rpc.darwinia.network"

begin
  block_number = Scale::Types.get("BlockNumberFor").new(670820)
  puts client.get_storage("EthereumRelayAuthorities", "MmrRootsToSign", [block_number]).to_human
rescue => ex
  puts ex.message
  puts ex.backtrace
end

