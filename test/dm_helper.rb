# Helper for testing paperclip using DataMapper

require './test/helper' # paperclip's test/helper
require File.join(File.dirname(__FILE__), '../lib/binderclip/orm/data_mapper')
require 'dm-migrations'

DataMapper.setup(:default, 'sqlite::memory:')

def rebuild_model options = {}
  rebuild_class(options)
end

def rebuild_class options = {}
  Object.send(:remove_const, "Dummy") rescue nil
  Object.const_set("Dummy", Class.new())
  Dummy.class_eval do
    include DataMapper::Resource
    include Binderclip::Orm::DataMapper::TestCompatibility

    property :id, DataMapper::Property::Serial
    property :other, String

    has_attached_file :avatar, options
  end

  DataMapper.auto_migrate!
end
