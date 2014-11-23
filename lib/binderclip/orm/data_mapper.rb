require 'dm-core'
require 'dm-validations'

module Binderclip
  module Orm
    module DataMapper
      # Extend a DM model to add has_attached_method, to be used as in AR
      # Paperclip. And additional option is available:
      #
      # apply_schema<Boolean>::
      #   Whether to add properties expected by paperclip. Defaults to True.
      module Hook
        # See paperclip documentation for usage details. This DM version adds
        # the following option:
        #
        # apply_schema<Boolean>::
        #   Whether to add properties expected by paperclip. Defaults to True.
        def has_attached_file name, options = {}
          include ActiveSupport::Callbacks
          extend PaperclipClassMethods
          include Paperclip::CallbackCompatability::Rails3
          include Binderclip::Orm::DataMapper::Compatibility
          include Paperclip::InstanceMethods

          # TODO Add a test for apply_schema => false
          apply_schema(name) unless (options.delete(:apply_schema) === false)

          write_inheritable_attribute(:attachment_definitions, {}) if attachment_definitions.nil?
          attachment_definitions[name] = {:validations => []}.merge(options)

          after :save, :save_attached_files
          before :destroy, :destroy_attached_files

          define_paperclip_callbacks :post_process, :"#{name}_post_process"

          define_method name do |*args|
            a = attachment_for(name)
            (args.length > 0) ? a.to_s(args.first) : a
          end

          define_method "#{name}=" do |file|
            attachment_for(name).assign(file)
          end

          define_method "#{name}?" do
            attachment_for(name).file?
          end

          validates_with_block do
            attachment = self.attachment_for(name)
            attachment_errors = attachment.send(:flush_errors)
            if attachment_errors.empty?
              true
            else
              [ false, name.to_s.capitalize + ' ' + attachment_errors.map{|category, msgs| msgs.join('; ')}.join('; ') ]
            end
          end
        end
      end

      # Paperclip::ClassMethods includes has_attached_file as well as methods
      # we don't override. In order to extend into the DM class when has_attached_file
      # is called, we need a copy of Paperclip::ClassMethods without has_attached_file
      # or else the second call to has_attached_file will fail (calling the
      # AR version included with Paperclip).
      #
      # I want to extend the class methods from the has_attached_file method
      # because I don't want to include Paperclip::ClassMethods and
      # ActiveSupport::Callbacks in all DM classes, nor do I want to have to
      # add "extend Binderclip::Orm::DataMapper::Hook" to the model definition before
      # using has_attached_file. Whether these goals are worth the weird code
      # is debatable.
      PaperclipClassMethods = Paperclip::ClassMethods.clone
      PaperclipClassMethods.send(:remove_method, :has_attached_file)

      # Add class and instance methods expected by paperclip by DM Model
      module Compatibility
        extend ActiveSupport::Concern

        module ClassMethods
          def apply_schema(name)
            property :"#{name}_file_name", String
            property :"#{name}_content_type", String
            property :"#{name}_file_size", Integer
            property :"#{name}_updated_at", DateTime
            property :"#{name}_fingerprint", String
          end

          def validates_attachment_content_type name, options = {}
            validation_options = options.dup
            allowed_types = [validation_options[:content_type]].flatten
            validates_with_block(:"#{name}_content_type") do
              value = attribute_get(:"#{name}_content_type")
              if !allowed_types.any?{|t| t === value } && !(value.nil? || value.blank?)
                message = options[:message] || "is not one of #{allowed_types.join(", ")}"
                [ false, message ]
              else
                true
              end
            end
          end

          def validates_inclusion_of(attr_name, options = {})
            options[:set] = options[:in]
            validates_within(attr_name, options)
          end

          def inherited(*args)
            inherited_with_inheritable_attributes(*args)
            super
          end
        end
      end

      # Active Record related methods that are used by Paperclip's tests to
      # setup or teardown the test's context but are not used internally by
      # paperclip. This module can be included in a test model but is not
      # included by has_attached_file.
      module TestCompatibility
        extend ActiveSupport::Concern

        module ClassMethods
          # See instance method #attributes= below for details
          def attr_protected(*args)
            @protected_attrs ||= []
            @protected_attrs += args
          end

          def protected_attrs
            @protected_attrs
          end

          def delete_all
            all.destroy!
          end

          # Add ActiveRecord like finder
          def find(*args)
            case args.first
            when :first, :all
              send(args.shift, *args)
            else
              get(*args)
            end
          end

          def has_many(name, options = {})
            if options[:class_name]
              options[:model] = options.delete(:class_name)
            end
            has Infinity, name, options
          end
        end

        # Override #attributes to emulate attr_protected functionality.
        # In AR, this prevents assigning an attribute within mass-assignment.
        # Paperclip tests that this works with an attachment attribute
        # (e.g. avatar=). I believe that just making the method private
        # or protected in DM (e.g. private :avatar=) will accomplish the same.
        def attributes=(attrs = {})
          if self.class.protected_attrs
            attrs.dup.each do |key, value|
              attrs.delete(key) if self.class.protected_attrs.include?(key)
            end
          end
          super
        end
      end
    end
  end
end

# User DataMapper logger instead of Active Record logger
module Paperclip
  class << self
    def logger #:nodoc:
      DataMapper.logger
    end
  end
end

DataMapper::Model.append_extensions(Binderclip::Orm::DataMapper::Hook)
