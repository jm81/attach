DataMapper.setup(:default, 'sqlite3::memory:')
require 'dm-timestamps' # Only needed to make #created_at and #updated_at auto-update

module Attach::Example
  class Photo
    include DataMapper::Resource
    include Attach::Attachment
    attachment_properties
  end
end

DataMapper.auto_migrate!
