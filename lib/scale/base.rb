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
      # new(1.to_u32, U32(69))
      def initialize(*args)
        raise ArgumentError, "Too many arguments" if args.size > self.class::ITEMS.size
        self::class::ITEMS.zip(args) do |attr, val|
          send "#{attr}=", val
        end
      end

      module ClassMethods
        def decode(scale_bytes)
          items = self::ITEM_TYPES.map do |item_type|
            item_type.constantize.decode(scale_bytes)
          end
          return self.new(*items)
        end

        def items(**items)
          attrs = []
          attr_types = []

          items.each_pair do |attr_name, attr_type|
            attrs << attr_name
            attr_types << attr_type
          end

          self.const_set(:ITEMS, attrs)
          self.const_set(:ITEM_TYPES, attr_types)
          self.attr_accessor *attrs
        end
      end

      def self.included(base)
        base.extend ClassMethods
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
            attr_types << attr_type
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
    end

    module Vector
      include SingleValue # value is an array

      module ClassMethods
        def decode(scale_bytes, raw=false)
          number = Scale::Types::Compact.decode(scale_bytes).value
          inner_type = self::INNER_TYPE.start_with?("Scale::Types::") ? self::INNER_TYPE : "Scale::Types::#{self::INNER_TYPE}"
          items = []
          number.times do
            
            item = inner_type.constantize.decode(scale_bytes)
            items << item
          end
          raw ? items : self.new(items)
        end

        def inner_type(type)
          self.const_set(:INNER_TYPE, type)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end

  end
end
