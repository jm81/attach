require 'rubygems'
require 'micronaut'
require 'attach'
require 'dm-validations'
require 'dm-migrations'

def not_in_editor?
  !(ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM'))
end

Micronaut.configure do |c|
  c.color_enabled = not_in_editor?
  c.filter_run :focused => true
end
