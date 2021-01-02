
class SubstrateClient::Helper
  class << self
    def generate_storage_key_from_metadata(metadata, module_name, storage_name, params = nil)
      # find the storage item from metadata
      metadata_modules = metadata.value.value[:metadata][:modules]
      metadata_module = metadata_modules.detect { |mm| mm[:name] == module_name }
      raise "Module '#{module_name}' not exist" unless metadata_module
      storage_item = metadata_module[:storage][:items].detect { |item| item[:name] == storage_name }
      raise "Storage item '#{storage_name}' not exist. \n#{metadata_module.inspect}" unless storage_item

      if storage_item[:type][:Plain]
        return_type = storage_item[:type][:Plain]
      elsif map = storage_item[:type][:Map]
        raise "Storage call of type \"Map\" requires 1 parameter" if params.nil? || params.length != 1

        hasher = map[:hasher]
        return_type = map[:value]
        # TODO: decode to account id if param is address
        # params[0] = decode(params[0]) if map[:key] == "AccountId"
        type = Scale::Types.get(map[:key])
        params[0] = type.new(params[0]).encode
      elsif map = storage_item[:type][:DoubleMap]
        raise "Storage call of type \"DoubleMapType\" requires 2 parameters" if params.nil? || params.length != 2

        hasher = map[:hasher]
        hasher2 = map[:key2Hasher]
        return_type = map[:value]
        params[0] = Scale::Types.get(map[:key1]).new(params[0]).encode
        params[1] = Scale::Types.get(map[:key2]).new(params[1]).encode
      else
        raise NotImplementedError
      end

      storage_key = generate_storage_key(
        module_name,
        storage_name,
        params,
        hasher,
        hasher2,
        metadata.value.value[:metadata][:version]
      )
      [storage_key, return_type]
    end

    def generate_storage_key(module_name, storage_name, params = nil, hasher = nil, hasher2 = nil, metadata_version = nil)
      if metadata_version and metadata_version >= 9
        storage_key = Crypto.twox128(module_name) + Crypto.twox128(storage_name)

        params&.each_with_index do |param, index|
          if index == 0
            param_hasher = hasher
          elsif index == 1
            param_hasher = hasher2
          else
            raise "Unexpected third parameter for storage call"
          end

          param_key = param.hex_to_bytes
          param_hasher = "Twox128" if param_hasher.nil?
          storage_key += Crypto.send(param_hasher.underscore, param_key)
        end

        "0x#{storage_key}"
      else
        # TODO: add test
        storage_key = module_name + " " + storage_name

        unless params.nil?
          params = [params] if params.class != ::Array
          params_key = params.join("")
          hasher = "Twox128" if hasher.nil?
          storage_key += params_key.hex_to_bytes.bytes_to_utf8 
        end

        "0x#{Crypto.send( hasher.underscore, storage_key )}"
      end
    end

    def compose_call_from_metadata(metadata, module_name, call_name, params)
      call = metadata.get_module_call(module_name, call_name)

      value = {
        call_index: call[:lookup],
        module_name: module_name,
        call_name: call_name,
        params: []
      }

      params.keys.each_with_index do |call_param_name, i|
        param_value = params[call_param_name]
        value[:params] << {
          name: call_param_name.to_s,
          type: call[:args][i][:type],
          value: param_value
        }
      end

      Scale::Types::Extrinsic.new(value).encode
    end

    def decode_block(block)
      block["block"]["header"]["number"] = block["block"]["header"]["number"].to_i(16)

      block["block"]["extrinsics"].each_with_index do |hex, i|
        scale_bytes = Scale::Bytes.new(hex)
        block["block"]["extrinsics"][i] = Scale::Types::Extrinsic.decode(scale_bytes).to_human
      end

      block['block']['header']["digest"]["logs"].each_with_index do |hex, i|
        scale_bytes = Scale::Bytes.new(hex)
        log = Scale::Types::LogDigest.decode(scale_bytes).to_human
        block['block']['header']["digest"]["logs"][i] = log
      end

      block
    end

  end
end
