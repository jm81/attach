require 'example_helper'
require 'attach/samples'

describe Attach::Attachment do
  before(:each) do
    @klass = Attach::Example::Photo
    
    @attrs = {
      :filename => 'test.jpg',
      :content_type => 'image/jpeg',
      :size => 100,
      :attachable_id => 1,
      :attachable_type => 'Attach::Spec::Person',
      :field_name => 'id_photo'
    }
    
    @photo = @klass.new(@attrs)
  end
  
  it 'should be valid' do
    @photo.should be_valid
  end
  
  describe '#position' do
    before(:each) do
      @klass.all.destroy!
    end
    
    it 'should default to 0 if first record' do
      @klass.all.destroy!
      @photo.save
      @photo.position.should == 0
    end
    
    it 'should be 1 greater than largest position (yes, unnecessarily high)' do
      @klass.all.destroy!
      @klass.create(:position => 3)
      @klass.create(:position => 6)
      @photo.save
      @photo.position.should == 7
    end
  end
  
  describe '#created_at and #updated_at' do
    it 'should record timestamps' do
      @photo.save
      @photo.created_at.should be_kind_of(DateTime)
      @photo.updated_at.should be_kind_of(DateTime)
    end
  end
  
  describe '#attachment_properties' do
    it 'should add properties' do
      klass = Class.new
      klass.__send__(:include, DataMapper::Resource)
      klass.__send__(:include, Attach::Attachment)
      klass.attachment_properties
      klass.properties.named?(:attachable_type).should be_true
      klass.properties.named?(:attachable_id).should be_true
    end
  end
end
