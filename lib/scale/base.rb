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

    module Primitive
      include SingleValue

      def self.encode(value)
        raise NotImplementedError
      end
    end

    module Enum
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          index = scale_bytes.get_next_bytes(1)[0]
          member_type = self::MEMBER_TYPES[index]
          raise "There is no such member with index #{index} for enum #{self}" if member_type.nil?
          value = member_type.decode(scale_bytes)
          return self.new(value)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
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
              value = self::INNER_TYPE.decode(scale_bytes)
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
    end


    module StructBase
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
            item_type.decode(scale_bytes)
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

    module Vector
      include SingleValue # value is an array

      module ClassMethods
        def decode(scale_bytes)
          number = Scale::Types::Compact.decode(scale_bytes).value
          items = []
          number.times do
            item = self::INNER_TYPE.decode(scale_bytes)
            items << item
          end
          self.new(items)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end

  end
end
