module Scale
  module Types

    class MetadataV3
      include SingleValue
      def self.decode(scale_bytes)
        modules = type_of("Vec<MetadataModule>").decode(scale_bytes).value;
        result = {
          magicNumber: 1635018093,
          metadata: {
            V3: {
              modules: modules.map(&:value)
            }
          }
        }

        MetadataV3.new(result)
      end
    end

  end
end
