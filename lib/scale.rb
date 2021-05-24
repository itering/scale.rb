require "scale/version"

require "common"

require "json"
require "singleton"

require "scale_bytes"

require "scale/base"
require "scale/types"
require "scale/block"
require "scale/trie"

require "type_builder"
require "type_registry"

require "metadata/metadata"
require "metadata/metadata_v0"
require "metadata/metadata_v1"
require "metadata/metadata_v2"
require "metadata/metadata_v3"
require "metadata/metadata_v4"
require "metadata/metadata_v5"
require "metadata/metadata_v6"
require "metadata/metadata_v7"
require "metadata/metadata_v8"
require "metadata/metadata_v9"
require "metadata/metadata_v10"
require "metadata/metadata_v11"
require "metadata/metadata_v12"

require "substrate_client"
require "logger"
require "helper"

module Scale
  class ScaleError < StandardError; end
  class TypeBuildError < ScaleError; end
  class BadDataError < ScaleError; end

  module Types
    class << self
      attr_accessor :debug
    end

    def self.check_types
      TypeRegistry.instance.all_types.keys.each do |key|
        begin
          type = self.get(key)
        rescue => ex
          puts "[[ERROR]] #{key}: #{ex}"
        end
      end
      true
    end

  end
end

def green(text)
  "\033[32m#{text}\033[0m"
end

def yellow(text)
  "\033[33m#{text}\033[0m"
end

class String
  def upcase_first
    self.sub(/\S/, &:upcase)
  end

  def camelize2
    self.split('_').collect(&:upcase_first).join
  end

  def underscore2
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

# https://www.ruby-forum.com/t/question-about-hex-signed-int/125510/4
# machine bit length:
#   machine_byte_length = ['foo'].pack('p').size
#   machine_bit_length = machine_byte_length * 8
class Integer
  def to_signed(bit_length)
    unsigned_mid = 2 ** (bit_length - 1)
    unsigned_ceiling = 2 ** bit_length
    (self >= unsigned_mid) ? self - unsigned_ceiling : self
  end

  def to_unsigned(bit_length)
    unsigned_mid = 2 ** (bit_length - 1)
    unsigned_ceiling = 2 ** bit_length 
    if self >= unsigned_mid || self <= -unsigned_mid
      raise "out of scope"
    end
    return unsigned_ceiling + self if self < 0
    self
  end
end

class ::Hash
  # via https://stackoverflow.com/a/25835016/2257038
  def stringify_keys
    h = self.map do |k,v|
      v_str = if v.instance_of? Hash
                v.stringify_keys
              else
                v
              end

      [k.to_s, v_str]
    end
    Hash[h]
  end
end

Scale::Types.debug = false
