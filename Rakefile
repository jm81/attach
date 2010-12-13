require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'bundler'
Bundler.setup(:default, :paperclip)
require File.join(File.dirname(__FILE__), 'lib', 'attach', 'version')

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "jm81-attach"
    gem.version = Attach::VERSION.dup
    gem.summary = %Q{Yet another Attachments library (for DataMapper)}
    gem.description = %Q{This is a library I've developed for attachments, because I just don't like the others I've tried.}
    gem.email = "jmorgan@morgancreative.net"
    gem.homepage = "http://github.com/jm81/attach"
    gem.authors = ["Jared Morgan"]
    gem.add_dependency('dm-core', '~> 1.0.2')
    gem.add_dependency('dm-aggregates', '~> 1.0.2')
    gem.add_dependency('dm-timestamps', '~> 1.0.2')
    gem.add_dependency('dm-types', '~> 1.0.2')
    gem.add_dependency('dm-validations', '~> 1.0.2')
    gem.add_development_dependency('dm-migrations', '~> 1.0.2')
    gem.add_development_dependency('micronaut', '>= 0.3.0')
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'micronaut/rake_task'
Micronaut::RakeTask.new(:examples) do |examples|
  examples.pattern = 'examples/**/*_example.rb'
  examples.ruby_opts << '-Ilib -Iexamples'
end

Micronaut::RakeTask.new(:rcov) do |examples|
  examples.pattern = 'examples/**/*_example.rb'
  examples.rcov_opts = '-Ilib -Iexamples'
  examples.rcov = true
end

task :examples

task :default => :examples

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "attach #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace 'test' do
  desc 'Run paperclip tests using DataMapper. Specify path to paperclip with PAPERCLIP_PATH'
  Rake::TestTask.new(:data_mapper) do |test|
    ENV['PAPERCLIP_PATH'] ||= File.expand_path('../paperclip')
    unless File.exist?(ENV['PAPERCLIP_PATH'])
      puts "Specify the path to devise (e.g. rake test:data_mapper PAPERCLIP_PATH=/path/to/devise). Not found at #{ENV['PAPERCLIP_PATH']}"
      exit
    end
    test.libs << 'lib' << 'test'
    Dir.chdir(ENV['PAPERCLIP_PATH']) if ARGV[0] == 'test:data_mapper'
    test.test_files = FileList["#{File.dirname(__FILE__)}/test/dm_helper.rb"] + FileList["#{ENV['PAPERCLIP_PATH']}/test/**/*_test.rb"]
    test.verbose = true
  end
end
