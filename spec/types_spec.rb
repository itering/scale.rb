require "scale"
require_relative "./types_for_test.rb"

module Scale
  module Types
    describe "hello" do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x45")
        o = U8.decode scale_bytes
        expect(o.value).to eql(69)
        expect(o.encode).to eql("45")

    end
    describe U8 do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x45")
        o = U8.decode scale_bytes
        expect(o.value).to eql(69)
        expect(o.encode).to eql("45")
      end
    end

    describe U16 do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x2a00")
        o = U16.decode scale_bytes
        expect(o.value).to eql(42)
        expect(o.encode).to eql("2a00")
      end
    end

    describe U32 do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0xffffff00")
        o = U32.decode scale_bytes
        expect(o.value).to eql(16_777_215)
        expect(o.encode).to eql("ffffff00")
      end
    end

    describe U64 do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x00e40b5403000000")
        o = U64.decode scale_bytes
        expect(o.value).to eql(14_294_967_296)
        expect(o.encode).to eql("00e40b5403000000")
      end
    end

    describe U128 do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x0bfeffffffffffff0000000000000000")
        o = U128.decode scale_bytes
        expect(o.value).to eql(18_446_744_073_709_551_115)
        expect(o.encode).to eql("0bfeffffffffffff0000000000000000")
      end
    end

    describe I16 do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x2efb")
        o = I16.decode scale_bytes
        expect(o.value).to eql(-1234)
      end
    end

    describe Bool do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x00")
        o = Bool.decode scale_bytes
        expect(o.value).to eql(false)
        expect(o.encode).to eql("00")

        scale_bytes = Scale::Bytes.new("0x01")
        o = Bool.decode scale_bytes
        expect(o.value).to eql(true)
        expect(o.encode).to eql("01")
      end
    end

    describe Compact do
      it "single-byte mode compact should work correctly" do
        scale_bytes = Scale::Bytes.new("0x00")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(0)
        expect(o.encode).to eql("00")

        scale_bytes = Scale::Bytes.new("0x04")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(1)
        expect(o.encode).to eql("04")

        scale_bytes = Scale::Bytes.new("0xa8")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(42)
        expect(o.encode).to eql("a8")

        scale_bytes = Scale::Bytes.new("0xfc")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(63)
        expect(o.encode).to eql("fc")
      end

      it "two-byte mode compact should work correctly" do
        scale_bytes = Scale::Bytes.new("0x1501")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(69)
        expect(o.encode).to eql("1501")
      end

      it "four-byte mode compact should work correctly" do
        scale_bytes = Scale::Bytes.new("0xfeffffff")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(1_073_741_823)
        expect(o.encode).to eql("feffffff")
      end

      it "big-integer mode compact should work correctly" do
        scale_bytes = Scale::Bytes.new("0x0300000040")
        o = Compact.decode scale_bytes
        expect(o.value).to eql(1_073_741_824)
        expect(o.encode).to eql("0300000040")
      end
    end

    describe Option do
      it "option bool should work correctly" do
        scale_bytes = Scale::Bytes.new("0x00")
        o = OptionBool.decode scale_bytes
        expect(o.value).to eql(nil)
        expect(o.encode).to eql("00")

        scale_bytes = Scale::Bytes.new("0x01")
        o = OptionBool.decode scale_bytes
        expect(o.value).to eql(false)
        expect(o.encode).to eql("01")
        # Rust SCALE does not implement Optional Booleans conformant to
        # specification yet, so this is commented for now

        scale_bytes = Scale::Bytes.new("0x02")
        o = OptionBool.decode scale_bytes
        expect(o.value).to eql(true)
        expect(o.encode).to eql("02")
        # Rust SCALE does not implement Optional Booleans conformant to
        # specification yet, so this is commented for now
      end

      it "option u32 should work correctly" do
        scale_bytes = Scale::Bytes.new("0x00")
        o = OptionU32.decode scale_bytes
        expect(o.value).to eql(nil)
        expect(o.encode).to eql("00")

        scale_bytes = Scale::Bytes.new("0x01ffffff00")
        o = OptionU32.decode scale_bytes
        expect(o.value.value).to eql(16_777_215)
        expect(o.encode).to eql("01ffffff00")
      end

      it "can be construct form type string" do
        scale_bytes = Scale::Bytes.new("0x01ffffff00")
        type = Scale::Types.type_of("Option<U32>")
        o = type.decode scale_bytes
        expect(o.value.value).to eql(16_777_215)
        expect(o.encode).to eql("01ffffff00")

        scale_bytes = Scale::Bytes.new("0x010c003afe")
        type = Scale::Types.type_of("Option<Vec<U8>>")
        expect(type.name).to eql("Scale::Types::Option_Of_Vec˂U8˃")
        o = type.decode scale_bytes
        expect(o.value.value.map(&:value)).to eql([0, 58, 254])
        expect(o.encode).to eql("010c003afe")

        scale_bytes = Scale::Bytes.new("0x0c0100013a01fe")
        type = Scale::Types.type_of("Vec<Option<U8>>")
        o = type.decode scale_bytes
        expect(o.value.map { |e| e.value.value }).to eql([0, 58, 254])
        expect(o.encode).to eql("0c0100013a01fe")
      end
    end

    describe Vec do
      it "vector u8 should work correctly" do
        scale_bytes = Scale::Bytes.new("0x0c003afe")
        o = VecU8.decode scale_bytes
        expect(o.value.map(&:value)).to eql([0, 58, 254])
        expect(o.encode).to eql("0c003afe")
      end

      it "Vec<U8> should work correctly" do
        scale_bytes = Scale::Bytes.new("0x0c003afe")
        o = Scale::Types.type_of("Vec<U8>").decode scale_bytes
        expect(o.value.map(&:value)).to eql([0, 58, 254])
        expect(o.encode).to eql("0c003afe")
      end

      it "Vec<BalanceLock> should work correctly" do
        # scale_bytes = Scale::Bytes.new("0x0876657374696e67207326160de7075e035823000000000000017374616b696e67208018179741946c6630a039000000000002")
        scale_bytes = Scale::Bytes.new("0x0c7374616b696e6720a18161b5b58201000000000000000000ffffffff1f706872656c6563740030434cc42501000000000000000000ffffffff1e64656d6f63726163ffffffffffffffffffffffffffffffffc0c0150002")
        o = Scale::Types.type_of("Vec<BalanceLock>").decode scale_bytes
        expect(o.value.length).to eql(3)

        first_balance_lock = o.value[0]
        second_balance_lock = o.value[1]
        third_balance_lock = o.value[2]

        [
          [
            [first_balance_lock.id, VecU8Length8, "staking "],
            [first_balance_lock.amount, Balance, 425_191_920_468_385],
            [first_balance_lock.until, U32, 4_294_967_295],
            [first_balance_lock.reasons, WithdrawReasons, %i[TransactionPayment Transfer Reserve Fee Tip]]
          ],
          [
            [second_balance_lock.id, VecU8Length8, "phrelect"],
            [second_balance_lock.amount, Balance, 323_000_000_000_000],
            [second_balance_lock.until, U32, 4_294_967_295],
            [second_balance_lock.reasons, WithdrawReasons, %i[Transfer Reserve Fee Tip]]
          ],
          [
            [third_balance_lock.id, VecU8Length8, "democrac"],
            [third_balance_lock.amount, Balance, 340_282_366_920_938_463_463_374_607_431_768_211_455],
            [third_balance_lock.until, U32, 1_425_600],
            [third_balance_lock.reasons, WithdrawReasons, [:Transfer]]
          ]
        ].each do |item|
          item.each do |(actual_value, expectation_type, expectation_value)|
            expect(actual_value.class).to eql(expectation_type)
            expect(actual_value.value).to eql(expectation_value)
          end
        end
        expect(o.encode).to eql("0c7374616b696e6720a18161b5b58201000000000000000000ffffffff1f706872656c6563740030434cc42501000000000000000000ffffffff1e64656d6f63726163ffffffffffffffffffffffffffffffffc0c0150002")
      end
    end

    describe Struct do
      it "Student should work correctly" do
        scale_bytes = Scale::Bytes.new("0x0100000045000045")
        o = Student.decode scale_bytes

        [
          [o.age, U32],
          [o.grade, U8],
          [o.courses_number, OptionU32],
          [o.int_or_bool, IntOrBool]
        ]
          .map { |(actual, expectation)| expect(actual.class).to eql(expectation) }

        [
          [o.age, 1],
          [o.grade, 69],
          [o.courses_number, nil],
          [o.int_or_bool.value, 69]
        ]
          .map { |(actual, expectation)| expect(actual.value).to eql(expectation) }

        expect(o.encode).to eql("0100000045000045")
      end
    end

    describe Tuple do
      it "should work correctly" do
        scale_bytes = Scale::Bytes.new("0x4545")
        o = TupleDoubleU8.decode scale_bytes
        expect(o.value.map(&:value)).to eql([69, 69])
        expect(o.encode).to eql("4545")
      end

      it "can be typed from type string" do
        klass = Scale::Types.type_of("(U8, U8)")
        expect(klass.name.start_with?("Scale::Types::Tuple")).to be true

        scale_bytes = Scale::Bytes.new("0x4545")
        o = klass.decode scale_bytes
        expect(o.value.map(&:value)).to eql([69, 69])
        expect(o.encode).to eql("4545")
      end
    end

    describe Enum do
      it "IntOrBool should work correctly" do
        scale_bytes = Scale::Bytes.new("0x0101")
        o = IntOrBool.decode scale_bytes
        expect(o.encode).to eql("0101")
        expect(o.value.value).to eql(true)

        scale_bytes = Scale::Bytes.new("0x002a")
        o = IntOrBool.decode scale_bytes
        expect(o.encode).to eql("002a")
        expect(o.value.value).to eql(42)
      end
    end

    describe Set do
      it "should work correctly" do
        o = WithdrawReasons.decode Scale::Bytes.new("0x01")
        expect(o.value).to eql([:TransactionPayment])
        expect(o.encode).to eql("01")

        o = WithdrawReasons.decode Scale::Bytes.new("0x03")
        expect(o.value).to eql(%i[TransactionPayment Transfer])
        expect(o.encode).to eql("03")

        o = WithdrawReasons.decode Scale::Bytes.new("0x16")
        expect(o.value).to eql(%i[Transfer Reserve Tip])
        expect(o.encode).to eql("16")
      end
    end

    describe Bytes do
      it "should work correctly when bytes are utf-8" do
        o = Bytes.decode Scale::Bytes.new("0x14436166c3a9")
        expect(o.value).to eql("Café")
        expect(o.encode).to eql("14436166c3a9")
      end

      it "should work correctly when bytes are not utf-8" do
        o = Bytes.decode Scale::Bytes.new("0x2cf6e6365010130543a3a416")
        expect(o.value).to eql("0xf6e6365010130543a3a416")
        expect(o.encode).to eql("2cf6e6365010130543a3a416")
      end
    end

    describe Address do
      it "should work correctly" do
        o = Address.decode Scale::Bytes.new("0xff0102030405060708010203040506070801020304050607080102030405060708")
        expect(o.value).to eql("0x0102030405060708010203040506070801020304050607080102030405060708")
        expect(o.encode).to eql("ff0102030405060708010203040506070801020304050607080102030405060708")

        o = Address.decode Scale::Bytes.new("0xfd11121314")
        expect(o.value).to eql("0x11121314")
        expect(o.encode).to eql("fd11121314")

        o = Address.decode Scale::Bytes.new("0xfc0001")
        expect(o.value).to eql("0x0001")
        expect(o.encode).to eql("fc0001")

        o = Address.decode Scale::Bytes.new("0x01")
        expect(o.value).to eql("0x01")
        expect(o.encode).to eql("01")
      end

      it "can encode to ss58" do
        o = Address.decode Scale::Bytes.new("0xff0102030405060708010203040506070801020304050607080102030405060708")
        expect(o.encode(true)).to eql("5C62W7ELLAAfix9LYrcx5smtcffbhvThkM5x7xfMeYXCtGwF")
        expect(o.encode(true, 18)).to eql("2oCCJJEf7BBDyYSCp5WP2FPh72EYPXMDDmnoMZE8Y2FW8HLi")
      end
    end

    describe VecU8Length8 do
      it "should work correctly with utf-8" do
        o = VecU8Length8.decode Scale::Bytes.new("0x6162636465666768")
        expect(o.value).to eql("abcdefgh")
        expect(o.encode).to eql("6162636465666768")
      end

      it "should work correctly with no utf-8" do
        o = VecU8Length8.decode Scale::Bytes.new("0x374656d343041636")
        expect(o.value).to eql("0x374656d343041636")
        expect(o.encode).to eql("374656d343041636")
      end
    end
  end
end
