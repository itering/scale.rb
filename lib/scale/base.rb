module Scale
  module Types

    module SingleValue
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(another)
        self.value == another.value
      end
    end

    # value: one of nil, false, true, scale object
    module Option
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          byte = scale_bytes.get_next_bytes(1)
          if byte == [0]
            return self.new(nil)
          elsif byte == [1]
            if self::INNER_TYPE_STR == 'boolean'
              return self.new(false)
            else
              # big process
              value = type_of(self::INNER_TYPE_STR).decode(scale_bytes)
              return self.new(value)
            end
          elsif byte == [2]
            if self::INNER_TYPE_STR == 'boolean'
              return self.new(true)
            else
              raise "bad data"
            end
          else
            raise "bad data"
          end
        end

        def inner_type(type_str)
          self.const_set(:INNER_TYPE_STR, type_str)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        # TODO: add Null type
        if self.value.nil?
          "00"
        else
          return "02" if self.value.class == TrueClass && self.value === true
          return "01" if self.value.class == FalseClass && self.value === false
          "01" + self.value.encode 
        end
      end
    end

    module FixedWidthUInt
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          class_name = self.to_s
          bytes = scale_bytes.get_next_bytes self::BYTES_LENGTH
          bytes_reversed = bytes.reverse
          hex = bytes_reversed.reduce('0x') { |hex, byte| hex + byte.to_s(16).rjust(2, '0') }
          self.new(hex.to_i(16))
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        bytes = self.value.to_s(16).rjust(self.class::BYTES_LENGTH*2, '0').scan(/.{2}/).reverse.map {|hex| hex.to_i(16) }
        bytes.bytes_to_hex[2..]
      end
    end


    module Struct
      include SingleValue
      # new(1.to_u32, U32(69))
      module ClassMethods
        def decode(scale_bytes)
          item_values = self::ITEM_TYPE_STRS.map do |item_type_str|
            type_of(item_type_str).decode(scale_bytes)
          end

          value = {}
          self::ITEM_NAMES.zip(item_values) do |attr, val|
            value[attr] = val
          end

          result = self.new(value)
          value.each_pair do |attr, val|
            result.send "#{attr}=", val
          end
          return result
        end

        def items(**items)
          attr_names = []
          attr_type_strs = []

          items.each_pair do |attr_name, attr_type_str|
            attr_names << attr_name
            attr_type_strs << attr_type_str
          end

          self.const_set(:ITEM_NAMES, attr_names)
          self.const_set(:ITEM_TYPE_STRS, attr_type_strs)
          self.attr_accessor *attr_names
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        [].tap do |result| 
          self.value.each_pair do |attr_name, attr_value|
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
            type_of(type_str).decode(scale_bytes)
          end
          return self.new(values)
        end

        def inner_types(*type_strs)
          self.const_set(:TYPE_STRS, type_strs)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        self.value.map(&:encode).join
      end
    end

    module Enum
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          index = scale_bytes.get_next_bytes(1)[0]
          if self.const_defined? "ITEM_NAMES"
            item_type_str = self::ITEM_TYPE_STRS[index]
            raise "There is no such member with index #{index} for enum #{self}" if item_type_str.nil?
            value = type_of(item_type_str).decode(scale_bytes)
            return self.new(value)
          else
            value = self::VALUES[index]
            return self.new(value)
          end
        end

        def items(**items)
          attr_names = []
          attr_type_strs = []

          items.each_pair do |attr_name, attr_type_str|
            attr_names << attr_name
            attr_type_strs << attr_type_str
          end

          self.const_set(:ITEM_NAMES, attr_names)
          self.const_set(:ITEM_TYPE_STRS, attr_type_strs)
        end

        def values(*values)
          self.const_set(:VALUES, values)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if self.class.const_defined? "ITEM_NAMES"
          value_type_str = self.value.class.to_s.split("::").last.to_s
          index = self::class::ITEM_TYPE_STRS.index(value_type_str).to_s(16).rjust(2, '0')
          index + self.value.encode
        else
          self::class::VALUES.index(self.value).to_s(16).rjust(2, '0')
        end
      end
    end

    module Vec
      include SingleValue # value is an array

      module ClassMethods
        def decode(scale_bytes, raw=false)
          number = Scale::Types::Compact.decode(scale_bytes).value
          items = []
          number.times do
            item = type_of(self::INNER_TYPE_STR).decode(scale_bytes)
            items << item
          end
          raw ? items : self.new(items)
        end

        def inner_type(type_str)
          self.const_set(:INNER_TYPE_STR, type_str)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        number = Scale::Types::Compact.new(self.value.length).encode
        [number].tap do |result|
          self.value.each do |element|
            result << element.encode
          end
        end.join
      end
    end

    module Set
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          value = "Scale::Types::U#{self::BYTES_LENGTH*8}".constantize.decode(scale_bytes).value
          return self.new [] if not value || value <= 0

          result = self::VALUES.select{ |_, mask| value & mask > 0 }.keys
          return self.new result
        end

        # values is a hash:
        #   {
        #     "TransactionPayment" => 0b00000001,
        #     "Transfer" => 0b00000010,
        #     "Reserve" => 0b00000100,
        #     ...
        #   }
        def values(values, bytes_length=1)
          raise "byte length is wrong: #{bytes_length}" if not [1, 2, 4, 8, 16].include?(bytes_length)
          self.const_set(:VALUES, values)
          self.const_set(:BYTES_LENGTH, bytes_length)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        value = self.class::VALUES.select{ |str, _| self.value.include?(str) }.values.sum
        "Scale::Types::U#{self.class::BYTES_LENGTH*8}".constantize.new(value).encode
      end
    end

    module VecU8FixedLength
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          class_name = self.to_s
          length = class_name[class_name.length-1]
          raise "length is wrong: #{length}" if not ["2", "3", "4", "8", "16", "20", "32", "64"].include?(length)
          length = length.to_i

          bytes = scale_bytes.get_next_bytes(length)
          str = bytes.pack("C*").force_encoding("utf-8")
          if str.valid_encoding?
            self.new str
          else
            self.new bytes.bytes_to_hex
          end
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        class_name = self.class.to_s
        length = class_name[class_name.length-1]
        raise "length is wrong: #{length}" if not ["2", "3", "4", "8", "16", "20", "32", "64"].include?(length)
        length = length.to_i

        if self.value.start_with?("0x") && self.value.length == (length*2+2) 
          self.value[2..]
        else
          bytes = self.value.unpack("C*")
          bytes.bytes_to_hex[2..]
        end
      end
    end

  end
end
