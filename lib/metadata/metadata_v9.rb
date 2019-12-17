module Scale
  module Types

    class MetadataV9
      include SingleValue
      def self.decode(scale_bytes)
        modules = type("Vec<MetadataV8Module>").decode(scale_bytes).value;
        result = {
          magicNumber: 1635018093,
          metadata: {
            V9: {
              modules: modules.map(&:value)
            }
          }
        }

        MetadataV9.new(result)
      end
    end

  end
end
