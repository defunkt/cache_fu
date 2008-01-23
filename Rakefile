require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'load_multi_rails_rake_tasks'

desc "Run all the tests"
task :default => :test

test_files = FileList['test/*test.rb']

desc 'Test the cache_fu plugin.'
task :test do
  test_files.each do |file|
    ruby "#{file}"
  end
end

desc 'Test the cache_fu plugin against Rails 1.2.5'
task :test_with_125 do
  ENV['MULTIRAILS_RAILS_VERSION'] = '1.2.5'
  test_files.each do |file|
    ruby "#{file}"
  end
end

desc "Run cache_fu tests using a memcache daemon"
task :test_with_memcache do
  test_files.each do |file|
    ruby "#{file} with-memcache"
  end
end

desc 'Generate RDoc documentation for the cache_fu plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  files = ['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "cache_fu"
  rdoc.template = File.exists?(t="/Users/chris/ruby/projects/err/rock/template.rb") ? t : "/var/www/rock/template.rb"
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--inline-source'
end
