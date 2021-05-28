
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
        if params[0].class != type
          raise Scale::StorageInputTypeError.new("The type of first param is not equal to the type from metadata: #{map[:key]} => #{type}")
        end
        params[0] = params[0].encode
      elsif map = storage_item[:type][:DoubleMap]
        raise "Storage call of type \"DoubleMapType\" requires 2 parameters" if params.nil? || params.length != 2

        hasher = map[:hasher]
        hasher2 = map[:key2Hasher]
        return_type = map[:value]

        type1 = Scale::Types.get(map[:key1])
        if params[0].class != type1
          raise Scale::StorageInputTypeError.new("The type of 1st param is not equal to the type from metadata: #{map[:key1]} => #{type1.class.name}")
        end
        params[0] = params[0].encode

        type2 = Scale::Types.get(map[:key2])
        if params[1].class != type2
          raise Scale::StorageInputTypeError.new("The type of 2nd param is not equal to the type from metadata: #{map[:key2]} => #{type2.class.name}")
        end
        params[1] = params[1].encode
      else
        raise NotImplementedError
      end

      storage_prefix = metadata_module[:storage][:prefix]
      storage_key = generate_storage_key(
        storage_prefix.nil? ? module_name : storage_prefix,
        storage_name,
        params,
        hasher,
        hasher2,
        metadata.value.value[:metadata][:version]
      )
      storage_modifier = storage_item[:modifier]
      [storage_key, return_type, storage_item]
    end

    def generate_storage_key(module_name, storage_name, params = nil, hasher = nil, hasher2 = nil, metadata_version = nil)
      metadata_version = 12 if metadata_version.nil?
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

          param_key = if param.class == String && param.start_with?("0x")
            param.hex_to_bytes
          else
            param.encode().hex_to_bytes
          end
          param_hasher = "Twox128" if param_hasher.nil?
          storage_key += Crypto.send(param_hasher.underscore2, param_key)
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

        "0x#{Crypto.send( hasher.underscore2, storage_key )}"
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

      block["block"]["extrinsics_decoded"] = []
      block["block"]["extrinsics"].each_with_index do |hex, i|
        scale_bytes = Scale::Bytes.new(hex)
        block["block"]["extrinsics_decoded"][i] = Scale::Types::Extrinsic.decode(scale_bytes).to_human
      end

      block['block']['header']["digest"]["logs_decoded"] = []
      block['block']['header']["digest"]["logs"].each_with_index do |hex, i|
        scale_bytes = Scale::Bytes.new(hex)
        log = Scale::Types::LogDigest.decode(scale_bytes).to_human
        block['block']['header']["digest"]["logs_decoded"][i] = log
      end

      block
    end

  end
end
