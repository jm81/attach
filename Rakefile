require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "jm81-attach"
    gem.summary = %Q{Yet another Attachments library (for DataMapper)}
    gem.description = %Q{This is a library I've developed for attachments, because I just don't like the others I've tried.}
    gem.email = "jmorgan@morgancreative.net"
    gem.homepage = "http://github.com/jm81/attach"
    gem.authors = ["Jared Morgan"]
    gem.add_dependency('dm-core', '>= 0.10.0')
    gem.add_dependency('dm-types', '>= 0.10.0')
    gem.add_dependency('dm-timestamps', '>= 0.10.0')
    gem.add_dependency('dm-aggregates', '>= 0.10.0')
    gem.add_development_dependency('micronaut', '>= 0.3.0')
    gem.add_dependency('dm-validations', '>= 0.10.0')
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

task :examples => :check_dependencies

task :default => :examples

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "attach #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
