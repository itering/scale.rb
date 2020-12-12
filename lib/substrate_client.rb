
def ws_request(url, payload)
  result = nil
  Kontena::Websocket::Client.connect(url, {}) do |client|
    client.send(payload.to_json)

    client.read do |message|
      result = JSON.parse message
      client.close(1000)
    end
  end

  return result
rescue Kontena::Websocket::CloseError => e
  raise SubstrateClient::WebsocketError, e.reason
rescue Kontena::Websocket::Error => e
  raise SubstrateClient::WebsocketError, e.reason
end

class SubstrateClient
  class WebsocketError < StandardError; end
  class RpcError < StandardError; end
  class RpcTimeout < StandardError; end

  attr_reader :metadata
  attr_reader :spec_name, :spec_version

  def initialize(url)
    @url = url
    @request_id = 1
    @metadata_cache = {}
  end

  def request(method, params)
    payload = {
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => params,
      "id" => @request_id
    }

    data = ws_request(@url, payload)
    if data["error"]
      raise RpcError, data["error"]
    else
      data["result"]
    end
  end

  def init_types_and_metadata(block_hash=nil)
    runtime_version = self.state_getRuntimeVersion(block_hash)
    spec_name = runtime_version["specName"].downcase
    spec_version = runtime_version["specVersion"]

    registry = Scale::TypeRegistry.instance

    # load types
    if registry.types == nil
      registry.load(spec_name: spec_name)
    end
    registry.spec_version = spec_version

    # set current metadata
    metadata = @metadata_cache[spec_version]
    if metadata.nil?
      metadata = self.get_metadata(block_hash)
      @metadata_cache[spec_version] = metadata
    end

    @metadata = metadata
    registry.metadata = metadata.value

    true
  end

  def get_metadata_from_cache(spec_version)

  end

  def invoke(method, *params)
    request(method, params)
  end

  # ################################################
  # origin rpc methods
  # ################################################
  def method_missing(method, *args)
    invoke method, *args
  end

  # ################################################
  # custom methods based on origin rpc methods
  # ################################################
  def methods
    invoke("rpc_methods")["methods"]
  end

  def get_block_number(block_hash)
    header = self.chain_getHeader(block_hash)
    header["number"].to_i(16)
  end

  def get_metadata(block_hash=nil)
    hex = self.state_getMetadata(block_hash)
    Scale::Types::Metadata.decode(Scale::Bytes.new(hex))
  end

  def get_block(block_hash=nil)
    self.init_types_and_metadata(block_hash)
    block = self.chain_getBlock(block_hash)
    SubstrateClient::Helper.decode_block(block)
  rescue => ex
    puts ex.message
    puts ex.backtrace.join("\n\t")
  end

  def get_block_events(block_hash=nil)
    self.init_types_and_metadata(block_hash)

    storage_key =  "0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7"
    events_data = state_getStorage storage_key, block_hash

    scale_bytes = Scale::Bytes.new(events_data)
    Scale::Types.get("Vec<EventRecord>").decode(scale_bytes).to_human
  end

  # Plain: client.get_storage("Sudo", "Key")
  # Plain: client.get_storage("Balances", "TotalIssuance")
  # Map: client.get_storage("System", "Account", ["0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"])
  # DoubleMap: client.get_storage("ImOnline", "AuthoredBlocks", [2818, "0x749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757"])
  def get_storage(module_name, storage_name, params = nil, block_hash = nil)
    self.init_types_and_metadata(block_hash)

    storage_key, return_type = SubstrateClient::Helper.generate_storage_key_from_metadata(@metadata, module_name, storage_name, params)

    result = self.state_getStorage(storage_key, block_hash)
    return unless result
    Scale::Types.get(return_type).decode(Scale::Bytes.new(result))
  end

  def generate_storage_key(module_name, storage_name, params = nil, block_hash = nil)
    self.init_types_and_metadata(block_hash)
    SubstrateClient::Helper.generate_storage_key_from_metadata(@metadata, module_name, storage_name, params)
  end

  # compose_call "Balances", "Transfer", { dest: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409", value: 1_000_000_000_000 }
  def compose_call(module_name, call_name, params, block_hash=nil)
    self.init_types_and_metadata(block_hash)
    SubstrateClient::Helper.compose_call_from_metadata(@metadata, module_name, call_name, params)
  end

  def generate_storage_hash_from_data(storage_hex_data)
    "0x" + Crypto.blake2_256(Scale::Bytes.new(storage_hex_data).bytes)
  end

end
