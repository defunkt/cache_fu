require 'yaml'
require 'erb'

namespace :memcached do
  desc "Start memcached locally" 
  task :start do
    memcached config_args
    puts "memcached started"
  end

  desc "Restart memcached locally" 
  task :restart do
    Rake::Task['memcached:stop'].invoke
    Rake::Task['memcached:start'].invoke
  end

  desc "Stop memcached locally" 
  task :stop do
    `killall memcached`
    puts "memcached killed"
  end
end

def config
  return @config if @config
  config  = YAML.load(ERB.new(IO.read(File.dirname(__FILE__) + '/../../../../config/memcached.yml')).result)
  @config = config['defaults'].merge(config['development'])
end

def config_args
  args = {
    '-p' => Array(config['servers']).first.split(':').last,
    '-c' => config['c_threshold'],
    '-m' => config['memory'],
    '-d' => ''
  }

  args.to_a * ' '
end

def memcached(*args)
  `/usr/bin/env memcached #{args * ' '}`
end
