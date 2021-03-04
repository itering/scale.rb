require 'xxhash'
require 'blake2b'
require 'base58'

class Array
  def bytes_to_hex
    raise "Not a byte array" unless self.is_byte_array?
    '0x' + self.map { |b| b.to_s(16).rjust(2, '0') }.join
  end

  def bytes_to_bin
    raise "Not a byte array" unless self.is_byte_array?
    '0b' + self.map { |b| b.to_s(2).rjust(8, '0') }.join
  end

  def bytes_to_bin
    raise "Not a byte array" unless self.is_byte_array?
    self.map { |b| b.to_s(2).rjust(8, '0') }
  end

  def bytes_to_utf8
    raise "Not a byte array" unless self.is_byte_array?
    self.pack('C*').force_encoding('utf-8')
  end

  def is_byte_array?
    self.all? {|e| e >= 0 and e <= 255 }
  end
end

class String
  def constantize2
    Object.const_get(self)
  end

  def hex_to_bytes
    data = self.start_with?('0x') ? self[2..] : self
    raise "Not valid hex string" if data.length % 2 != 0
    data.scan(/../).map(&:hex)
  end
end

module Crypto
  def self.identity(bytes)
    bytes.bytes_to_hex[2..]
  end

  def self.twox64(data)
    result = XXhash.xxh64 data, 0
    bytes = result.to_s(16).rjust(16, '0').hex_to_bytes.reverse
    bytes.bytes_to_hex[2..]
  end

  def self.twox128(data)
    bytes = []
    2.times do |i|
      result = XXhash.xxh64 data, i
      bytes = bytes + result.to_s(16).rjust(16, '0').hex_to_bytes.reverse
    end
    bytes.bytes_to_hex[2..]
  end

  def self.twox64_concat(bytes)
    data = bytes.bytes_to_utf8
    twox64(data) + bytes.bytes_to_hex[2..]
  end

  def self.blake2_128(bytes)
    data = bytes.bytes_to_utf8
    Blake2b.hex data, Blake2b::Key.none, 16
  end

  def self.blake2_256(bytes)
    data = bytes.bytes_to_utf8
    Blake2b.hex data, Blake2b::Key.none, 32
  end

  def self.blake2_128_concat(bytes)
    blake2_128(bytes) + bytes.bytes_to_hex[2..]
  end
end

class Address
  SS58_PREFIX = 'SS58PRE'

  TYPES = [
    # Polkadot Live (SS58, AccountId)
    0, 1,
    # Polkadot Canary (SS58, AccountId)
    2, 3,
    # Kulupu (SS58, Reserved)
    16, 17,
    # Darwinia Live
    18,
    # Dothereum (SS58, AccountId)
    20, 21, 
    # Generic Substrate wildcard (SS58, AccountId)
    42, 43,

    # Schnorr/Ristretto 25519 ("S/R 25519") key
    48,
    # Edwards Ed25519 key
    49,
    # ECDSA SECP256k1 key
    50,

    # Reserved for future address format extensions.
    *64..255
  ]

  class << self

    def array_to_hex_string(arr)
      body = arr.map { |i| i.to_s(16).rjust(2, '0') }.join
      "0x#{body}"
    end

    def decode(address, addr_type = 42, ignore_checksum = true)
      decoded = Base58.base58_to_binary(address, :bitcoin)
      is_pubkey = decoded.size == 35

      size = decoded.size - ( is_pubkey ? 2 : 1 )

      prefix = decoded[0, 1].unpack("C*").first

      raise "Invalid address type" unless TYPES.include?(addr_type)
      
      hash_bytes = make_hash(decoded[0, size])
      if is_pubkey
        is_valid_checksum = decoded[-2].unpack("C*").first == hash_bytes[0] && decoded[-1].unpack("C*").first == hash_bytes[1]
      else
        is_valid_checksum = decoded[-1].unpack("C*").first == hash_bytes[0]
      end

      raise "Invalid decoded address checksum" unless is_valid_checksum && ignore_checksum

      decoded[1...size].unpack("H*").first
    end


    def encode(pubkey, addr_type = 42)
      pubkey = pubkey[2..-1] if pubkey =~ /^0x/i
      key = [pubkey].pack("H*")

      u8_array = key.bytes

      u8_array.unshift(addr_type)

      bytes = make_hash(u8_array.pack("C*"))
      
      checksum = bytes[0, key.size == 32 ? 2 : 1]

      u8_array.push(*checksum)

      input = u8_array.pack("C*")

      Base58.binary_to_base58(input, :bitcoin)
    end

    def make_hash(body)
      Blake2b.bytes("#{SS58_PREFIX}#{body}", Blake2b::Key.none, 64)
    end

  end
end
