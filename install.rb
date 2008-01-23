##
# Do some checks.
puts

$errors = 0

puts "** Checking for memcached in path..."
if `which memcached`.strip.empty?
  $errors += 1
  puts "!! Couldn't find memcached in your path.  Are you sure you installed it? !!"
  puts "!! Check the README for help.  You can't use acts_as_cached without it.  !!"
end

puts "** Checking for memcache-client gem..."
begin
  require 'rubygems'
  require 'memcache'
rescue LoadError
  $errors += 1
  puts "!! Couldn't find memcache-client gem.  You can't use acts_as_cached without it. !!"
  puts "!! $ sudo gem install memcache-client                                           !!"
end

require 'fileutils'
def copy_file(in_file, out_file)
  puts "** Trying to copy #{File.basename(in_file)} to #{out_file}..."
  begin
    if File.exists? out_file
      puts "!! You already have a #{out_file}.  " +  
           "Please check the default for new settings or format changes. !!"
      puts "!! You can find the default at #{in_file}. !!"
      $errors += 1
    else
      FileUtils.cp(in_file, out_file)
    end
  rescue
    $errors += 1
    puts "!! Error copying #{File.basename(in_file)} to #{out_file}.  Please try by hand. !!"
  end
end

defaults_dir = File.join(File.dirname(__FILE__), 'defaults')

config_yaml  = File.join('.', 'config', 'memcached.yml')
default_yaml = File.join(defaults_dir, 'memcached.yml.default')
copy_file(default_yaml, config_yaml)

memcached_ctl = File.join('.', 'script', 'memcached_ctl')
default_ctl   = File.join(defaults_dir, 'memcached_ctl.default')
copy_file(default_ctl, memcached_ctl)

puts
print $errors.zero? ? "**" : "!!"
print " acts_as_cached installed with #{$errors.zero? ? 'no' : $errors} errors."
print " Please edit the memcached.yml file to your liking."
puts  $errors.zero? ? "" : " !!"
puts "** Now would be a good time to check out the README.  Enjoy your day."
puts
