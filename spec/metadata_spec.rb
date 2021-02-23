require "scale"
require "json"
require "pathname"
require "open-uri"

ROOT = Pathname.new File.expand_path("../../", __FILE__)
Scale::TypeRegistry.instance.load(spec_name: "kusama")
Scale::TypeRegistry.instance.spec_version = 1054

def get_metadata_hex(version)
  File.open(File.join(ROOT, "spec", "metadata", "v#{version}", "hex")).read.strip
end

def get_metadata(version)
  content = File.open(File.join(ROOT, "spec", "metadata", "v#{version}", "expect.json")).read.strip
  JSON.parse(content, symbolize_names: true)
end

describe Scale::Types::Metadata do
  it "can decode v0 hex data" do
    hex = get_metadata_hex(0)
    scale_bytes = Scale::Bytes.new(hex)
    metadata = Scale::Types::Metadata.decode(scale_bytes)
    v = metadata.value.value[:metadata]

    expected = get_metadata(0)

    expect(metadata.version).to eql(0)
    expect(v[:outerEvent][:events].length).to eql(expected[:outerEvent][:events].length)
    expect(v[:modules].length).to eql(expected[:modules].length)
    expect(v[:outerDispatch][:calls].length).to eql(expected[:outerDispatch][:calls].length)

    expect(v.to_json).to eql(expected.to_json)
  end

  # The data copy from polkadot-js/api about type and hasher has some errors,
  # so I did not test these.
  [1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12].each do |v|
    it "can decode v#{v} hex data" do
      hex = get_metadata_hex(v)
      scale_bytes = Scale::Bytes.new(hex)
      metadata = Scale::Types::Metadata.decode scale_bytes
      md = metadata.value.value[:metadata]
      mods = md[:modules]

      expected = get_metadata(v)[:metadata]["V#{v}".to_sym]
      mods_expected = expected[:modules]

      expect(metadata.version).to eql(v)

      mods.each_with_index do |mod, i|
        mod_expected = mods_expected[i]

        mod[:events]&.each_with_index do |event, j|
          event_expected = mod_expected[:events][j]
          expect(event[:name]).to eql(event_expected[:name])
          expect(event[:documentation]).to eql(event_expected[:documentation])
        end

        mod[:calls]&.each_with_index do |call, j|
          call_expected = mod_expected[:calls][j]
          expect(call[:name]).to eql(call_expected[:name])
          expect(call[:documentation]).to eql(call_expected[:documentation])
        end

        if not mod[:storage].nil?
          if mod[:storage].class.name == "Hash"
            storages = mod[:storage][:items]
            storages_expected = mod_expected[:storage][:items]
          else
            storages = mod[:storage]
            storages_expected = mod_expected[:storage]
          end

          storages.each_with_index do |storage, j|
            storage_expected = storages_expected[j]
            expect(storage[:name]).to eql(storage_expected[:name])
            expect(storage[:modifier]).to eql(storage_expected[:modifier])
            expect(storage[:fallback]).to eql(storage_expected[:fallback])
            expect(storage[:documentation]).to eql(storage_expected[:documentation])
          end
        end
      end
    end
  end

end
