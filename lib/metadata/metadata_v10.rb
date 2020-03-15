module Scale
  module Types
    class MetadataV10
      include SingleValue
      def self.decode(scale_bytes)
        modules = Scale::Types.type_of('Vec<MetadataV8Module>').decode(scale_bytes).value
        result = {
          magicNumber: 1_635_018_093,
          metadata: {
            V10: {
              modules: modules.map(&:value)
            }
          }
        }

        MetadataV10.new(result)
      end
    end
  end
end
