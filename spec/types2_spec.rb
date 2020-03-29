require "scale"
require_relative "./types_for_test.rb"

describe Scale::Types do
  before(:all) { Scale::TypeRegistry.instance.load }

  it "can correctly encode and decode U8" do
    scale_bytes = Scale::Bytes.new("0x45")
    o = Scale::Types::U8.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("45")
  end

  it "can correctly encode and decode U16" do
    scale_bytes = Scale::Bytes.new("0x2efb")
    o = Scale::Types::U16.decode scale_bytes
    expect(o.value).to eql(64302)
    expect(o.encode).to eql("2efb")
  end

  it "can correctly encode and decode U32" do
    scale_bytes = Scale::Bytes.new("0xffffff00")
    o = Scale::Types::U32.decode scale_bytes
    expect(o.value).to eql(16_777_215)
    expect(o.encode).to eql("ffffff00")
  end

  it "can correctly encode and decode U64" do
    scale_bytes = Scale::Bytes.new("0x00e40b5403000000")
    o = Scale::Types::U64.decode scale_bytes
    expect(o.value).to eql(14_294_967_296)
    expect(o.encode).to eql("00e40b5403000000")
  end

  it "can correctly encode and decode U128" do
    scale_bytes = Scale::Bytes.new("0x0bfeffffffffffff0000000000000000")
    o = Scale::Types::U128.decode scale_bytes
    expect(o.value).to eql(18_446_744_073_709_551_115)
    expect(o.encode).to eql("0bfeffffffffffff0000000000000000")
  end

  it "can correctly encode and decode I16" do
    scale_bytes = Scale::Bytes.new("0x2efb")
    o = Scale::Types::I16.decode scale_bytes
    expect(o.value).to eql(-1234)
    expect(o.encode).to eql("2efb")
  end


  it "can correctly encode and decode Bool" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::Bool.decode scale_bytes
    expect(o.value).to eql(false)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01")
    o = Scale::Types::Bool.decode scale_bytes
    expect(o.value).to eql(true)
    expect(o.encode).to eql("01")
  end

  it "can correctly decode and encode single-byte mode compact" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(0)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x04")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1)
    expect(o.encode).to eql("04")

    scale_bytes = Scale::Bytes.new("0xa8")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(42)
    expect(o.encode).to eql("a8")

    scale_bytes = Scale::Bytes.new("0xfc")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(63)
    expect(o.encode).to eql("fc")
  end

  it "can correctly decode and encode two-byte mode compact" do
    scale_bytes = Scale::Bytes.new("0x1501")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(69)
    expect(o.encode).to eql("1501")
  end

  it "can correctly decode and encode four-byte mode compact" do
    scale_bytes = Scale::Bytes.new("0xfeffffff")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1_073_741_823)
    expect(o.encode).to eql("feffffff")
  end

  it "can correctly decode and encode big-integer mode compact" do
    scale_bytes = Scale::Bytes.new("0x0300000040")
    o = Scale::Types::Compact.decode scale_bytes
    expect(o.value).to eql(1_073_741_824)
    expect(o.encode).to eql("0300000040")
  end

  it "can correctly decode and encode option bool" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::OptionBool.decode scale_bytes
    expect(o.value).to eql(nil)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01")
    o = Scale::Types::OptionBool.decode scale_bytes
    expect(o.value).to eql(false)
    expect(o.encode).to eql("01")
    # Rust SCALE does not implement Optional Booleans conformant to
    # specification yet, so this is commented for now

    scale_bytes = Scale::Bytes.new("0x02")
    o = Scale::Types::OptionBool.decode scale_bytes
    expect(o.value).to eql(true)
    expect(o.encode).to eql("02")
    # Rust SCALE does not implement Optional Booleans conformant to
    # specification yet, so this is commented for now
  end

  it "can correctly decode and encode option u32" do
    scale_bytes = Scale::Bytes.new("0x00")
    o = Scale::Types::OptionU32.decode scale_bytes
    expect(o.value).to eql(nil)
    expect(o.encode).to eql("00")

    scale_bytes = Scale::Bytes.new("0x01ffffff00")
    o = Scale::Types::OptionU32.decode scale_bytes
    expect(o.value.value).to eql(16_777_215)
    expect(o.encode).to eql("01ffffff00")
  end

  it "can be constantized form type string" do
    scale_bytes = Scale::Bytes.new("0x01ffffff00")
    klass = Scale::Types.type_of("Option<U32>")
    o = klass.decode scale_bytes
    expect(o.value.value).to eql(16_777_215)
    expect(o.encode).to eql("01ffffff00")

    scale_bytes = Scale::Bytes.new("0x010c003afe")
    klass = Scale::Types.type_of("Option<Vec<U8>>")
    expect(klass.name).to start_with("Scale::Types::Option_Of_Vec˂U8˃")
    o = klass.decode scale_bytes
    expect(o.value.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("010c003afe")

    scale_bytes = Scale::Bytes.new("0x0c0100013a01fe")
    klass = Scale::Types.type_of("Vec<Option<U8>>")
    o = klass.decode scale_bytes
    expect(o.value.map { |e| e.value.value }).to eql([0, 58, 254])
    expect(o.encode).to eql("0c0100013a01fe")

    klass = Scale::Types.type_of("(U8, U8)")
    expect(klass.name.start_with?("Scale::Types::Tuple")).to be true
    scale_bytes = Scale::Bytes.new("0x4545")
    o = klass.decode scale_bytes
    expect(o.value.map(&:value)).to eql([69, 69])
    expect(o.encode).to eql("4545")
  end

  it "can correctly decode and encode VecU8" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    o = Scale::Types::VecU8.decode scale_bytes
    expect(o.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("0c003afe")
  end

  it "can correctly decode and encode Vec<U8>" do
    scale_bytes = Scale::Bytes.new("0x0c003afe")
    o = Scale::Types.type_of("Vec<U8>").decode scale_bytes
    expect(o.value.map(&:value)).to eql([0, 58, 254])
    expect(o.encode).to eql("0c003afe")
  end

  it "can correctly decode and encode Vec<BalanceLock>" do
    # scale_bytes = Scale::Bytes.new("0x0876657374696e67207326160de7075e035823000000000000017374616b696e67208018179741946c6630a039000000000002")
    scale_bytes = Scale::Bytes.new("0x0c7374616b696e6720a18161b5b58201000000000000000000ffffffff1f706872656c6563740030434cc42501000000000000000000ffffffff1e64656d6f63726163ffffffffffffffffffffffffffffffffc0c0150002")
    klass = Scale::Types.type_of("Vec<BalanceLock>")
    o = klass.decode scale_bytes
    expect(o.value.length).to eql(3)

    first_balance_lock = o.value[0]
    second_balance_lock = o.value[1]
    third_balance_lock = o.value[2]

    [
      [
        [first_balance_lock.id, Scale::Types::VecU8Length8, "staking "],
        [first_balance_lock.amount, Scale::Types::Balance, 425_191_920_468_385],
        [first_balance_lock.until, Scale::Types::U32, 4_294_967_295],
        [first_balance_lock.reasons, Scale::Types::WithdrawReasons, %i[TransactionPayment Transfer Reserve Fee Tip]]
      ],
      [
        [second_balance_lock.id, Scale::Types::VecU8Length8, "phrelect"],
        [second_balance_lock.amount, Scale::Types::Balance, 323_000_000_000_000],
        [second_balance_lock.until, Scale::Types::U32, 4_294_967_295],
        [second_balance_lock.reasons, Scale::Types::WithdrawReasons, %i[Transfer Reserve Fee Tip]]
      ],
      [
        [third_balance_lock.id, Scale::Types::VecU8Length8, "democrac"],
        [third_balance_lock.amount, Scale::Types::Balance, 340_282_366_920_938_463_463_374_607_431_768_211_455],
        [third_balance_lock.until, Scale::Types::U32, 1_425_600],
        [third_balance_lock.reasons, Scale::Types::WithdrawReasons, [:Transfer]]
      ]
    ].each do |item|
      item.each do |(actual_value, expectation_type, expectation_value)|
        expect(actual_value.class).to eql(expectation_type)
        expect(actual_value.value).to eql(expectation_value)
      end
    end
    expect(o.encode).to eql("0c7374616b696e6720a18161b5b58201000000000000000000ffffffff1f706872656c6563740030434cc42501000000000000000000ffffffff1e64656d6f63726163ffffffffffffffffffffffffffffffffc0c0150002")
  end

  it "can correctly decode and encode struct" do
    scale_bytes = Scale::Bytes.new("0x0100000045000045")
    o = Scale::Types::Student.decode scale_bytes

    [
      [o.age, Scale::Types::U32],
      [o.grade, Scale::Types::U8],
      [o.courses_number, Scale::Types::OptionU32],
      [o.int_or_bool, Scale::Types::IntOrBool]
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

  it "can correctly decode and encode TupleDoubleU8" do
    scale_bytes = Scale::Bytes.new("0x4545")
    o = Scale::Types::TupleDoubleU8.decode scale_bytes
    expect(o.value.map(&:value)).to eql([69, 69])
    expect(o.encode).to eql("4545")
  end

  it "can correctly decode and encode enum" do
    scale_bytes = Scale::Bytes.new("0x0101")
    o = Scale::Types::IntOrBool.decode scale_bytes
    expect(o.encode).to eql("0101")
    expect(o.value.value).to eql(true)

    scale_bytes = Scale::Bytes.new("0x002a")
    o = Scale::Types::IntOrBool.decode scale_bytes
    expect(o.encode).to eql("002a")
    expect(o.value.value).to eql(42)
  end

  it "can correctly decode and encode set" do
    o = Scale::Types::WithdrawReasons.decode Scale::Bytes.new("0x01")
    expect(o.value).to eql([:TransactionPayment])
    expect(o.encode).to eql("01")

    o = Scale::Types::WithdrawReasons.decode Scale::Bytes.new("0x03")
    expect(o.value).to eql(%i[TransactionPayment Transfer])
    expect(o.encode).to eql("03")

    o = Scale::Types::WithdrawReasons.decode Scale::Bytes.new("0x16")
    expect(o.value).to eql(%i[Transfer Reserve Tip])
    expect(o.encode).to eql("16")
  end

  it "can correctly decode and encode Bytes when value is utf-8" do
    o = Scale::Types::Bytes.decode Scale::Bytes.new("0x14436166c3a9")
    expect(o.value).to eql("Café")
    expect(o.encode).to eql("14436166c3a9")
  end

  it "can correctly decode and encode Bytes when value is not utf-8" do
    o = Scale::Types::Bytes.decode Scale::Bytes.new("0x2cf6e6365010130543a3a416")
    expect(o.value).to eql("0xf6e6365010130543a3a416")
    expect(o.encode).to eql("2cf6e6365010130543a3a416")
  end

  it "can correctly decode and encode Address" do
    o = Scale::Types::Address.decode Scale::Bytes.new("0xff0102030405060708010203040506070801020304050607080102030405060708")
    expect(o.value).to eql("0x0102030405060708010203040506070801020304050607080102030405060708")
    expect(o.encode).to eql("ff0102030405060708010203040506070801020304050607080102030405060708")

    o = Scale::Types::Address.decode Scale::Bytes.new("0xfd11121314")
    expect(o.value).to eql("0x11121314")
    expect(o.encode).to eql("fd11121314")

    o = Scale::Types::Address.decode Scale::Bytes.new("0xfc0001")
    expect(o.value).to eql("0x0001")
    expect(o.encode).to eql("fc0001")

    o = Scale::Types::Address.decode Scale::Bytes.new("0x01")
    expect(o.value).to eql("0x01")
    expect(o.encode).to eql("01")
  end

  it "can encode account id to ss58" do
    o = Scale::Types::Address.decode Scale::Bytes.new("0xff0102030405060708010203040506070801020304050607080102030405060708")
    expect(o.encode(true)).to eql("5C62W7ELLAAfix9LYrcx5smtcffbhvThkM5x7xfMeYXCtGwF")
    expect(o.encode(true, 18)).to eql("2oCCJJEf7BBDyYSCp5WP2FPh72EYPXMDDmnoMZE8Y2FW8HLi")
  end

  it "can correctly decode and encode fixed length u8 vector when value is utf-8" do
    o = Scale::Types::VecU8Length8.decode Scale::Bytes.new("0x6162636465666768")
    expect(o.value).to eql("abcdefgh")
    expect(o.encode).to eql("6162636465666768")
  end

  it "can correctly decode and encode fixed length u8 vector when value is not utf-8" do
    o = Scale::Types::VecU8Length8.decode Scale::Bytes.new("0x374656d343041636")
    expect(o.value).to eql("0x374656d343041636")
    expect(o.encode).to eql("374656d343041636")
  end
end

