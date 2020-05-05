module Scale
  module Types

    module SingleValue
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(other)
        value == other.value
      end
    end

    # value: one of nil, false, true, scale object
    module Option
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          byte = scale_bytes.get_next_bytes(1)
          if byte == [0]
            new(nil)
          elsif byte == [1]
            if self::INNER_TYPE_STR == "boolean"
              new(false)
            else
              # big process
              value = Scale::Types.get(self::INNER_TYPE_STR).decode(scale_bytes)
              new(value)
            end
          elsif byte == [2]
            if self::INNER_TYPE_STR == "boolean"
              new(true)
            else
              raise "bad data"
            end
          else
            raise "bad data"
          end
        end

        def inner_type(type_str)
          const_set(:INNER_TYPE_STR, type_str)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        # TODO: add Null type
        if value.nil?
          "00"
        else
          return "02" if value.class == TrueClass && value === true
          return "01" if value.class == FalseClass && value === false
          "01" + value.encode
        end
      end
    end

    module FixedWidthInt
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          bit_length = to_s[15..].to_i
          byte_length = bit_length / 8
          bytes = scale_bytes.get_next_bytes byte_length
          value = bytes.reverse.bytes_to_hex.to_i(16).to_signed(bit_length)
          new(value)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if value.class != ::Integer
          raise "#{self.class}'s value must be integer"
        end
        bit_length = self.class.name[15..].to_i
        hex = value.to_unsigned(bit_length).to_s(16).hex_to_bytes.reverse.bytes_to_hex
        hex[2..]
      end
    end

    module FixedWidthUInt
      include SingleValue

      module ClassMethods
        attr_accessor :byte_length

        def decode(scale_bytes)
          bytes = scale_bytes.get_next_bytes self::BYTE_LENGTH
          bytes_reversed = bytes.reverse
          hex = bytes_reversed.reduce("0x") { |hex, byte| hex + byte.to_s(16).rjust(2, "0") }
          new(hex.to_i(16))
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if value.class != ::Integer
          raise "#{self.class}'s value must be integer"
        end
        bytes = value.to_s(16).rjust(self.class::BYTE_LENGTH * 2, "0").scan(/.{2}/).reverse.map {|hex| hex.to_i(16) }
        bytes.bytes_to_hex[2..]
      end
    end


    module Struct
      include SingleValue
      # new(1.to_u32, U32(69))
      module ClassMethods
        def decode(scale_bytes)
          item_values = self::ITEM_TYPE_STRS.map do |item_type_str|
            type = Scale::TypeRegistry.instance.get(item_type_str)
            type.decode(scale_bytes)
          end

          value = {}
          self::ITEM_NAMES.zip(item_values) do |attr, val|
            value[attr] = val
          end

          result = new(value)
          value.each_pair do |attr, val|
            result.send "#{attr}=", val
          end
          result
        end

        def items(items)
          attr_names = []
          attr_type_strs = []

          items.each_pair do |attr_name, attr_type_str|
            attr_names << attr_name.to_s.gsub("-", "")
            attr_type_strs << attr_type_str
          end

          const_set(:ITEM_NAMES, attr_names)
          const_set(:ITEM_TYPE_STRS, attr_type_strs)
          attr_accessor *attr_names
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        [].tap do |result|
          value.each_pair do |attr_name, attr_value|
            result << attr_value.encode
          end
        end.join
      end
    end

    module Tuple
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          values = self::TYPE_STRS.map do |type_str|
            Scale::Types.get(type_str).decode(scale_bytes)
          end
          new(values)
        end

        def inner_types(*type_strs)
          const_set(:TYPE_STRS, type_strs)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        value.map(&:encode).join
      end
    end

    module Enum
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          index = scale_bytes.get_next_bytes(1)[0]
          if const_defined? "ITEM_TYPE_STRS"
            item_type_str = self::ITEM_TYPE_STRS[index]
            raise "There is no such member with index #{index} for enum #{self}" if item_type_str.nil?
            value = Scale::Types.get(item_type_str).decode(scale_bytes)
          else
            value = self::VALUES[index]
          end
          new(value)
        end

        def items(items)
          if items.class == Hash
            attr_names = []
            attr_type_strs = []

            items.each_pair do |attr_name, attr_type_str|
              attr_names << attr_name
              attr_type_strs << attr_type_str
            end

            const_set(:ITEM_NAMES, attr_names)
            const_set(:ITEM_TYPE_STRS, attr_type_strs)
          elsif items.class == Array
            const_set(:ITEM_TYPE_STRS, items)
          end
        end

        def values(*values)
          const_set(:VALUES, values)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if self.class.const_defined? "ITEM_NAMES"
          value_type_str = value.class.to_s.split("::").last.to_s
          index = self.class::ITEM_TYPE_STRS.index(value_type_str).to_s(16).rjust(2, "0")
          index + value.encode
        else
          self.class::VALUES.index(value).to_s(16).rjust(2, "0")
        end
      end
    end

    module Vec
      include SingleValue # value is an array

      module ClassMethods
        def decode(scale_bytes, raw = false)
          number = Scale::Types::Compact.decode(scale_bytes).value
          items = []
          number.times do
            item = Scale::Types.get(self::INNER_TYPE_STR).decode(scale_bytes)
            items << item
          end
          raw ? items : new(items)
        end

        def inner_type(type_str)
          const_set(:INNER_TYPE_STR, type_str)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        number = Scale::Types::Compact.new(value.length).encode
        [number].tap do |result|
          value.each do |element|
            result << element.encode
          end
        end.join
      end
    end

    module Set
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          value = "Scale::Types::U#{self::BYTES_LENGTH * 8}".constantize.decode(scale_bytes).value
          return new [] unless value || value <= 0

          result = self::ITEMS.select { |_, mask| value & mask > 0 }.keys
          new result
        end

        # items is a hash:
        #   {
        #     "TransactionPayment" => 0b00000001,
        #     "Transfer" => 0b00000010,
        #     "Reserve" => 0b00000100,
        #     ...
        #   }
        def items(items, bytes_length = 1)
          raise "byte length is wrong: #{bytes_length}" unless [1, 2, 4, 8, 16].include?(bytes_length)
          const_set(:ITEMS, items)
          const_set(:BYTES_LENGTH, bytes_length)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        value = self.class::ITEMS.select { |key, _| self.value.include?(key) }.values.sum
        "Scale::Types::U#{self.class::BYTES_LENGTH * 8}".constantize.new(value).encode
      end
    end

    module VecU8FixedLength
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          byte_length = name[25..]
          raise "length is wrong: #{byte_length}" unless %w[2 3 4 8 16 20 32 64].include?(byte_length)
          byte_length = byte_length.to_i

          bytes = scale_bytes.get_next_bytes(byte_length)
          str = bytes.pack("C*").force_encoding("utf-8")
          if str.valid_encoding?
            new str
          else
            new bytes.bytes_to_hex
          end
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        class_name = self.class.to_s
        length = class_name[25..]
        raise "length is wrong: #{length}" unless %w[2 3 4 8 16 20 32 64].include?(length)
        length = length.to_i

        if value.start_with?("0x") && value.length == (length * 2 + 2)
          value[2..]
        else
          bytes = value.unpack("C*")
          bytes.bytes_to_hex[2..]
        end
      end
    end

  end
end
