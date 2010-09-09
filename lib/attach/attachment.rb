module Attach
  module Attachment
    class << self
      def included(klass)
        klass.extend(ClassMethods)
        klass.before(:destroy, :delete_files)
      end
    end # class << self
    
    module ClassMethods
      
      # Setup properties. Already added properties are not overriden.
      def attachment_properties()
        klass = self
        [
          [:id, DataMapper::Property::Serial],
          [:filename, String],
          [:content_type, String],
          [:size, Integer],
          [:attachable_id, Integer],
          [:attachable_type, String],
          [:field_name, String],
          # Default position may be rather high, but I don't really care
          [:position, Integer, {:default => Proc.new { |photo, prop| (klass.max(:position) || -1) + 1 }}],
          [:created_at, DateTime],
          [:updated_at, DateTime]
        ].each do |args|
          unless self.properties.named?(args[0])
            self.property(*args)
          end
        end
      end
    end # module ClassMethods
    
    def url(format = :full)
      "/assets/#{self.id}/#{format}/#{self.filename}"
    end
    
    def dir
      "public/assets/#{self.id}"
    end
    
    def path(format = :full)
      "#{self.dir}/#{format}/#{self.filename}"
    end
    
    def delete_files
      FileUtils.rmtree(self.dir)
    end
  end
end
