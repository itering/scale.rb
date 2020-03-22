require "scale"
require "json"
require "pathname"
require "open-uri"

ROOT = Pathname.new File.expand_path("../../", __FILE__)

def get_metadata_hex(version)
  File.open(File.join(ROOT, "spec", "metadata", "v#{version}", "hex")).read.strip
end

def get_metadata(version)
  content = File.open(File.join(ROOT, "spec", "metadata", "v#{version}", "expect.json")).read.strip
  JSON.parse content
end

# def get_metadata_hex(version)
  # url = "https://raw.githubusercontent.com/polkadot-js/api/master/packages/metadata/src/Metadata/v#{version}/static.ts"
  # open(url).read.each_line do |line|
    # if line.start_with?("const")
      # return line.scan(/const meta = '(.+)';/).first.first
    # end
  # end
# end

# def get_metadata_json(version)
  # url = "https://raw.githubusercontent.com/polkadot-js/api/master/packages/metadata/src/Metadata/v#{version}/static-substrate.json"
  # open(url).read
# end

describe Scale::Types::Metadata do
  it "can decode v0 hex data" do
    hex = get_metadata_hex(0)
    scale_bytes = Scale::Bytes.new(hex)
    metadata = Scale::Types::Metadata.decode(scale_bytes)
    v0 = metadata.value.value[:metadata][:V0]

    expected = get_metadata(0)

    expect(metadata.version).to eql(0)
    expect(v0[:outerEvent][:events].length).to eql(expected["outerEvent"]["events"].length)
    expect(v0[:modules].length).to eql(expected["modules"].length)
    expect(v0[:outerDispatch][:calls].length).to eql(expected["outerDispatch"]["calls"].length)

    expect(v0.to_json).to eql(expected.to_json)
  end

  # fixed: the v4 metadata hex from polkadot-js/api is not correct
  (1 .. 11).each do |i|
    it "can decode v#{i} hex data" do
      hex = get_metadata_hex(i)
      scale_bytes = Scale::Bytes.new(hex)
      metadata = Scale::Types::Metadata.decode scale_bytes
      v = metadata.value.value[:metadata]["V#{i}".to_sym]

      expected = get_metadata(i)["metadata"]["V#{i}"]

      expect(metadata.version).to eql(i)
      expect(v[:modules].length).to eql(expected["modules"].length)
    end
  end

end
