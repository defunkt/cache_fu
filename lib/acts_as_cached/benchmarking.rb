require 'benchmark'

module ActsAsCached
  module Benchmarking #:nodoc:
    def self.cache_runtime
      @@cache_runtime ||= 0.0
    end

    def self.cache_reset_runtime
      @@cache_runtime = nil
    end

    def cache_benchmark(title, log_level = Logger::DEBUG, use_silence = true)
      return yield unless logger && logger.level == log_level
      result = nil

      seconds = Benchmark.realtime {
        result = use_silence ? ActionController::Base.silence { yield } : yield
      }

      @@cache_runtime ||= 0.0
      @@cache_runtime += seconds

      logger.add(log_level, "==> #{title} (#{'%.5f' % seconds})")
      result
    end

    def fetch_cache_with_benchmarking(*args)
      cache_benchmark "Got #{cache_key args.first} from cache." do
        fetch_cache_without_benchmarking(*args)
      end
    end

    def set_cache_with_benchmarking(*args)
      cache_benchmark "Set #{cache_key args.first} to cache." do
        set_cache_without_benchmarking(*args)
      end
    end

    def expire_cache_with_benchmarking(*args)
      cache_benchmark "Deleted #{cache_key args.first} from cache." do
        expire_cache_without_benchmarking(*args)
      end
    end

    def self.add_to(klass)
      return if klass.respond_to? :fetch_cache_with_benchmarking
      klass.extend self

      class << klass
        alias_method_chain :fetch_cache,  :benchmarking
        alias_method_chain :set_cache,    :benchmarking
        alias_method_chain :expire_cache, :benchmarking

        def logger; RAILS_DEFAULT_LOGGER end unless respond_to? :logger
      end
    end

    def self.inject_into_logs!
      ActionController::Base.send :alias_method_chain, :rendering_runtime, :memcache
    end
  end
end

module ActionController
  class Base 
    def rendering_runtime_with_memcache(runtime) #:nodoc:
      cache_runtime = ActsAsCached::Benchmarking.cache_runtime
      ActsAsCached::Benchmarking.cache_reset_runtime
      rendering_runtime_without_memcache(runtime) + (cache_runtime.nonzero? ? " | Memcache: #{"%.5f" % cache_runtime}" : '')
    end
  end
end 
