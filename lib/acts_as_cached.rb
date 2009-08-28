require 'acts_as_cached/config'
require 'acts_as_cached/cache_methods'
require 'acts_as_cached/fragment_cache'
require 'acts_as_cached/benchmarking' 
require 'acts_as_cached/disabled'
require 'acts_as_cached/local_cache'

module ActsAsCached
  @@config = {}
  mattr_reader :config

  def self.config=(options)
    @@config = Config.setup options
  end

  def self.skip_cache_gets=(boolean)
    ActsAsCached.config[:skip_gets] = boolean
  end

  module Mixin
    def acts_as_cached(options = {})
      extend  ClassMethods
      include InstanceMethods

      extend  Extensions::ClassMethods    if defined? Extensions::ClassMethods
      include Extensions::InstanceMethods if defined? Extensions::InstanceMethods

      options.symbolize_keys!

      options[:store] ||= ActsAsCached.config[:store] 
      options[:ttl]   ||= ActsAsCached.config[:ttl] 

      # convert the find_by shorthand
      if find_by = options.delete(:find_by)
        options[:finder]   = "find_by_#{find_by}".to_sym
        options[:cache_id] = find_by
      end
      
      cache_config.replace  options.reject { |key,| not Config.valued_keys.include? key }
      cache_options.replace options.reject { |key,| Config.valued_keys.include? key }

      Disabled.add_to self and return if ActsAsCached.config[:disabled]
      Benchmarking.add_to self if ActsAsCached.config[:benchmarking]
    end
  end

  class CacheException < StandardError; end
  class NoCacheStore   < CacheException; end
  class NoGetMulti     < CacheException; end
end
