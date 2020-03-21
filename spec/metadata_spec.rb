require "scale"
require 'pathname'
require 'open-uri'

ROOT = Pathname.new File.expand_path('../../', __FILE__)
def get_metadata_hex(version)
  url = "https://raw.githubusercontent.com/polkadot-js/api/master/packages/metadata/src/Metadata/v#{version}/static.ts"
  open(url).read.each_line do |line|
    if line.start_with?("const")
      return line.scan(/const meta = '(.+)';/).first.first
    end
  end
end

describe Scale::Types::Metadata do

  it "can decode v3 hex data" do
    content = get_metadata_hex(3)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  # the v4 metadata hex from polkadot-js/api is not correct
  it "can decode v4 hex data" do
    content = File.open(File.join(ROOT, "spec", "v4")).read.strip
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v5 hex data" do
    content = get_metadata_hex(5)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v6 hex data" do
    content = get_metadata_hex(6)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v7 hex data" do
    content = get_metadata_hex(7)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v8 hex data" do
    content = get_metadata_hex(8)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v9 hex data" do
    content = get_metadata_hex(9)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v10 hex data" do
    content = get_metadata_hex(10)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end

  it "can decode v11 hex data" do
    content = get_metadata_hex(11)
    scale_bytes = Scale::Bytes.new(content)
    meta = Scale::Types::Metadata.decode scale_bytes
  end
end
