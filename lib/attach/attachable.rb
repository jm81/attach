require 'ftools'
require 'fileutils'
require 'RMagick'

# Example:
#
#    class Person
#      include Attach::Attachable

#      attachment  :id_photo, Photo, [[:full, 400, 300, '#eee'], [:medium, 260, 195, '#eee'], [:thumb, 96, 72, '#eee']]
#      attachments :photos, Photo, [[:full, 400, 300, '#eee'], [:medium, 260, 195, '#eee'], [:thumb, 96, 72, '#eee']]
#    end
#
# Person.id_photo => Photo
# Person.photos => Array/Collection of Photo
# Person.photo  => first Photo

module Attach
  module Attachable
    include FileUtils
    
    class << self
      def included(klass) # Set a few 'magic' properties
        klass.extend(::Attach::Attachable::ClassMethods)
        klass.after(:create, :assign_attachment_ids)
      end
    end
    
    module ClassMethods
      DEFAULT_SIZES = [[:full, 400, 300, '#eee'], [:thumb, 96, 72, '#eee']]
      
      # For models with single photo
      def attachment(fld, klass, sizes = nil)
        self.__send__(:instance_variable_set, "@#{fld}_sizes".to_sym, sizes)
        
        # def photo
        define_method(fld) do
          return nil unless self.id
          klass.first(:attachable_type => self.class.name, :attachable_id => self.id, :field_name => fld, :order => [:position.asc])
        end
        
        # def photos
        define_method(fld.to_s.pluralize) do
          if self.id
            klass.all(:attachable_type => self.class, :attachable_id => self.id, :field_name => fld, :order => [:position.asc])
          else
            []
          end
        end
        
        # def klass.photo_sizes
        singleton_class = class << self; self; end
        singleton_class.send(:define_method, "#{fld}_sizes") do
          instance_variable_get("@#{fld}_sizes".to_sym) || DEFAULT_SIZES
        end
        
        # def new_photo=
        define_method("new_#{fld}=") do |upload|
          photo = klass.create( :attachable_type => self.class,
                                :attachable_id => self.id,
                                :filename => upload.original_filename.split(/[\\\/]/)[-1],
                                :content_type => upload.content_type,
                                :size => upload.size,
                                :field_name => fld
          )
          
          if photo.filename[-4..-1].downcase == ".pdf"
            photo.update(:filename => photo.filename[0..-4] + "png")
          end
          
          @attachments_needing_id ||= Hash.new{ |hash, key| hash[key] = Array.new }
          @attachments_needing_id[fld.to_s] << photo unless self.id
          
          self.class.__send__("#{fld}_sizes").each do |style|
            dir_path = "public/assets/#{photo.id}/#{style[0]}"
            File.makedirs(dir_path)
            img = Magick::Image.read(upload.path)
            img[0].
              resize_matte(style[1], style[2], style[3]).
              write(photo.path(style[0]))
          end
        end
        
        # def replace_photo=
        # Deletes any current photos and adds a new photo
        define_method("replace_#{fld}=") do |upload|
          return false if upload.blank?
          self.__send__(fld.to_s.pluralize).each {|del_photo| del_photo.destroy}
          self.__send__("new_#{fld}=", upload)
        end
        
        # def destroy_photo_attachments=
        # 
        # Delete all attachments of attachment class. Called by before :destroy
        define_method("destroy_#{fld}_attachments") do
          self.__send__(fld.to_s.pluralize).destroy!
        end
        
        self.before(:destroy, "destroy_#{fld}_attachments".to_sym)
      end
      
      def attachments(fld, klass, sizes = nil)
        attachment(fld.to_s.singularize, klass, sizes)
        
        define_method("new_#{fld}=") do |uploads|
          uploads.each { |upload| self.__send__("new_#{fld.to_s.singularize}=", upload) }
        end
        
        define_method("delete_#{fld}=") do |del_photos|
          del_photos.each { |id| self.__send__(fld).get(id).destroy }
        end
      end
    end
    
    def assign_attachment_ids
      return unless @attachments_needing_id
      @attachments_needing_id.each do |fld, ary|  
        (ary || []).each do |att|
          att.update(:attachable_id => self.id)
        end
      end
      @attachments_needing_id = nil
    end
    
  end
end
