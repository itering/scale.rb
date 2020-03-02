module Scale
  module Types

    class MetadataV10
      include SingleValue
      def self.decode(scale_bytes)
        modules = type_of("Vec<MetadataV8Module>").decode(scale_bytes).value;
        result = {
          magicNumber: 1635018093,
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
