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
            if self::INNER_TYPE == 'boolean'
              return self.new(false)
            else
              # big process
              value = self::INNER_TYPE.constantize.decode(scale_bytes)
              return self.new(value)
            end
          elsif byte == [2]
            if self::INNER_TYPE == 'boolean'
              return self.new(true)
            else
              raise "bad data"
            end
          else
            raise "bad data"
          end
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
          item_values = self::ITEM_TYPES.map do |item_type|
            item_type.constantize.decode(scale_bytes)
          end

          value = {}
          self::ITEMS.zip(item_values) do |attr, val|
            value[attr] = val
          end

          result = self.new(value)
          value.each_pair do |attr, val|
            result.send "#{attr}=", val
          end
          return result
        end

        def items(**items)
          attrs = []
          attr_types = []

          items.each_pair do |attr_name, attr_type|
            attrs << attr_name
            attr_types << (attr_type.start_with?("Scale::Types::") ? attr_type : "Scale::Types::#{attr_type}")
          end

          self.const_set(:ITEMS, attrs)
          self.const_set(:ITEM_TYPES, attr_types)
          self.attr_accessor *attrs
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

    module Enum
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          index = scale_bytes.get_next_bytes(1)[0]
          if self.const_defined? "ITEMS"
            item_type = self::ITEM_TYPES[index]
            raise "There is no such member with index #{index} for enum #{self}" if item_type.nil?
            value = item_type.constantize.decode(scale_bytes)
            return self.new(value)
          else
            value = self::VALUES[index]
            return self.new(value)
          end
        end

        def items(**items)
          attrs = []
          attr_types = []

          items.each_pair do |attr_name, attr_type|
            attrs << attr_name
            attr_types << (attr_type.start_with?("Scale::Types::") ? attr_type : "Scale::Types::#{attr_type}")
          end

          self.const_set(:ITEMS, attrs)
          self.const_set(:ITEM_TYPES, attr_types)
        end

        def values(*values)
          self.const_set(:VALUES, values)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if self.class.const_defined? "ITEMS"
          index = self::class::ITEM_TYPES.index(self.value.class.to_s).to_s(16).rjust(2, '0')
          index + self.value.encode
        else
          self::class::VALUES.index(self.value).to_s(16).rjust(2, '0')
        end
      end
    end

    module Vector
      include SingleValue # value is an array

      module ClassMethods
        def decode(scale_bytes, raw=false)
          number = Scale::Types::Compact.decode(scale_bytes).value
          items = []
          number.times do
            item = self::INNER_TYPE.constantize.decode(scale_bytes)
            items << item
          end
          raw ? items : self.new(items)
        end

        def inner_type(type)
          inner_type = type.start_with?("Scale::Types::") ? type : "Scale::Types::#{type}"
          self.const_set(:INNER_TYPE, inner_type)
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

  end
end
