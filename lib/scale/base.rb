module Scale
  module Types

    module SingleValue
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(other)
        self.class == other.class && self.value == other.value
      end

      def to_human
        if @value.class == ::Hash
          @value.transform_values do |v|
            if v.class.included_modules.include?(SingleValue)
              v.to_human
            else
              v
            end
          end
        elsif @value.class == ::Array
          @value.map do |v|
            if v.class.included_modules.include?(SingleValue)
              v.to_human
            else
              v
            end
          end
        else
          @value
        end
      end

      module ClassMethods
        def inherited(child)
          child.const_set(:TYPE_NAME, child.name)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.const_set(:TYPE_NAME, base.name)
      end
    end

    # if value is bool, see type `OptionBool`
    module Option
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          byte = scale_bytes.get_next_bytes(1)
          if byte == [0]
            puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
            new(nil)
          elsif byte == [1]
            # big process
            value = self::INNER_TYPE.decode(scale_bytes)
            puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
            new(value)
          else
            raise BadDataError.new("Bad scale data for #{self::TYPE_NAME}")
          end
        end

        def inner_type(type)
          const_set(:INNER_TYPE, type)
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
          "01" + value.encode
        end
      end
    end

    module FixedWidthInt
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          bytes = scale_bytes.get_next_bytes self::BYTE_LENGTH
          bit_length = bytes.length.to_i * 8
          value = bytes.reverse.bytes_to_hex.to_i(16).to_signed(bit_length)
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
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
        bit_length = self.class::BYTE_LENGTH * 8
        hex = value.to_unsigned(bit_length).to_s(16).hex_to_bytes.reverse.bytes_to_hex
        hex[2..]
      end
    end

    module FixedWidthUInt
      include SingleValue

      module ClassMethods
        attr_accessor :byte_length

        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          bytes = scale_bytes.get_next_bytes self::BYTE_LENGTH
          bytes_reversed = bytes.reverse
          hex = bytes_reversed.reduce("0x") { |hex, byte| hex + byte.to_s(16).rjust(2, "0") }
          result = new(hex.to_i(16))

          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true

          result
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if value.class != ::Integer
          raise "#{self.class}'s value must be integer"
        end
        byte_length = self.class::BYTE_LENGTH
        bytes = value.to_s(16).rjust(byte_length * 2, "0").scan(/.{2}/).reverse.map {|hex| hex.to_i(16) }
        bytes.bytes_to_hex[2..]
      end
    end

    module Struct
      include SingleValue
      # new(1.to_u32, U32(69))
      module ClassMethods
        def inherited(child)
          child.const_set(:TYPE_NAME, child.name)
        end

        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true

          # {
          #   "id" => ...a,
          #   ...
          # }
          item_values = self::ITEMS.map do |item|
            item_name = item[0]
            item_type = item[1]
            [item_name, item_type.decode(scale_bytes)]
          end.to_h

          # value = {}
          # self::ITEM_NAMES.zip(item_values) do |attr, val|
          #   value[attr] = val
          # end

          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true

          result = new(item_values)
          item_values.each_pair do |item_name, item_value|
            result.send "#{item_name}=", item_value
          end

          result
        end

        def items(items)
          const_set(:ITEMS, items)
          item_names = items.map do |item|
            item[0]
          end
          attr_accessor *item_names
        end
      end

      def self.included(base)
        base.extend ClassMethods
        base.const_set(:TYPE_NAME, base.name)
      end

      def encode
        value.values.map do |item_value|
          item_value.encode
        end.join
      end
    end

    module Tuple
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true

          values = self::INNER_TYPES.map do |type|
            type.decode(scale_bytes)
          end

          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new(values)
        end

        # inner_types Scale::Types::U8, Scale::Types::U8
        def inner_types(*inner_types)
          const_set(:INNER_TYPES, inner_types)
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

      attr_accessor :index

      module ClassMethods
        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          index = scale_bytes.get_next_bytes(1)[0]
          if const_defined? "ITEMS"
            item = self::ITEMS[index]
            raise "There is no such member with index #{index} for enum #{self}" if item.nil?
            type = item.class == ::Array ? item[1] : item
            value = type.decode(scale_bytes)
          else # VALUES
            value = self::VALUES[index]
          end
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          result = new(value)
          result.index = index
          result
        end

        # ["Compact", "Hex"]
        # [["Item1", "Compact"], [["Item2", "Hex"]]
        def items(items)
          const_set(:ITEMS, items)
        end

        # [1, "hello"]
        def values(*values)
          const_set(:VALUES, values)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def encode
        if self.class.const_defined? "ITEMS"
          index.to_s(16).rjust(2, "0") + value.encode
        else
          self.class::VALUES.index(value).to_s(16).rjust(2, "0")
        end
      end

      def to_human
        if self.class.const_defined? "ITEMS"
          @value.to_human
        else
          @value
        end
      end
    end

    module Vec
      include SingleValue # value is an array

      module ClassMethods
        def decode(scale_bytes, raw = false)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          number = Scale::Types::Compact.decode(scale_bytes).value
          items = []
          number.times do
            item = self::INNER_TYPE.decode(scale_bytes)
            items << item
          end
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          raw ? items : new(items)
        end

        def inner_type(type)
          const_set(:INNER_TYPE, type)
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
          puts "  BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          value = "Scale::Types::U#{self::BYTE_LENGTH * 8}".constantize2.decode(scale_bytes).value
          return new [] unless value || value <= 0

          result = self::ITEMS.select { |_, mask| value & mask > 0 }.keys
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
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
          const_set(:BYTE_LENGTH, bytes_length)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        value = self.class::ITEMS.select { |key, _| self.value.include?(key) }.values.sum
        "Scale::Types::U#{self.class::BYTE_LENGTH * 8}".constantize2.new(value).encode
      end
    end

    module VecU8FixedLength
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          puts "  BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          byte_length = self::BYTE_LENGTH
          raise "#{self.name} byte length is wrong: #{byte_length}" unless %w[2 3 4 8 16 20 32 64 128 256].include?(byte_length.to_s)

          bytes = scale_bytes.get_next_bytes(byte_length)
          str = bytes.pack("C*").force_encoding("utf-8")
          if str.valid_encoding?
            puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
            new str
          else
            puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
            new bytes.bytes_to_hex
          end
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        byte_length = self.class::BYTE_LENGTH
        raise "#{self.class.name}'s byte length is wrong: #{byte_length}" unless %w[2 3 4 8 16 20 32 64 128 256].include?(byte_length.to_s)

        if value.start_with?("0x") && value.length == (byte_length * 2 + 2)
          value[2..]
        else
          bytes = value.unpack("C*")
          bytes.bytes_to_hex[2..]
        end
      end
    end

    module Array
      include SingleValue

      module ClassMethods
        def decode(scale_bytes)
          puts "BEGIN " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          items = (0 ... self::LENGTH).map do |_|
            self::INNER_TYPE.decode(scale_bytes)
          end
          puts "  END " + self::TYPE_NAME + ": #{scale_bytes}" if Scale::Types.debug == true
          new(items)
        end

        def inner_type(type)
          const_set(:INNER_TYPE, type)
        end

        def length(len)
          const_set(:LENGTH, len)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      def encode
        self.value.map do |item|
          item.encode
        end.join
      end
    end


  end
end
