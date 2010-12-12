# DataMapper
#
# This is code to add to the end of paperclip's test/helper.rb to run (and pass)
# paperclip's test suite using DataMapper. A few tests still do ActiveRecord
# work that I don't believe effects the quality of testing DM (primarily adding
# columns to the ActiveRecord dummies table in attachment_test.rb).
#
# This is just the first step in creating a DM compability layer.
#
# Add the following lines to the paperclip Gemfile:
# gem 'dm-core',           '~> 1.0.2'
# gem 'dm-migrations',     '~> 1.0.2'
# gem 'dm-sqlite-adapter', '~> 1.0.2'
# gem 'dm-types',          '~> 1.0.2'
# gem 'dm-validations',    '~> 1.0.2'

require 'dm-core'
require 'dm-migrations'
require 'dm-types'
require 'dm-validations'

DataMapper.setup(:default, 'sqlite::memory:')

def rebuild_model options = {}
  rebuild_class(options)
end

module DMCompat
  def after_save(*args)
    after(:save, *args)
  end

  def before_destroy(*args)
    before(:destroy, *args)
  end

  def has_attached_file name, options = {}
    super

    validates_with_block do
      attachment = self.attachment_for(name)
      attachment_errors = attachment.send(:flush_errors)
      if attachment_errors.empty?
        true
      else
        [ false, name.to_s.capitalize + ' ' + attachment_errors[:processing][0] ]
      end
    end
  end

  def validates_each(name, &block)
    return true
  end

  def validates_attachment_content_type name, options = {}
    validation_options = options.dup
    allowed_types = [validation_options[:content_type]].flatten
    validates_with_block(:"#{name}_content_type", validation_options) do
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

  def attr_protected(*args)
    @protected_attrs ||= []
    @protected_attrs += args
  end

  def protected_attrs
    @protected_attrs
  end

  def has_many(name, options = {})
    if options[:class_name]
      options[:model] = options.delete(:class_name)
    end
    has Infinity, name, options
  end

  def inherited(*args)
    inherited_with_inheritable_attributes(*args)
    super
  end
end

def rebuild_class options = {}
  Object.send(:remove_const, "Dummy") rescue nil
  Object.const_set("Dummy", Class.new())
  Dummy.class_eval do
    include DataMapper::Resource
    include ActiveSupport::Callbacks
    include Paperclip::Glue
    extend DMCompat

    property :id, DataMapper::Property::Serial
    property :other, String
    property :avatar_file_name, String
    property :avatar_content_type, String
    property :avatar_file_size, Integer
    property :avatar_updated_at, DateTime
    property :avatar_fingerprint, String

    def attributes=(attrs = {})
      if self.class.protected_attrs
        attrs.dup.each do |key, value|
          attrs.delete(key) if self.class.protected_attrs.include?(key)
        end
      end
      super
    end

    has_attached_file :avatar, options
  end

  DataMapper.auto_migrate!
end
