module ActsAsCached
  module Disabled
    def fetch_cache_with_disabled(*args)
      nil
    end

    def set_cache_with_disabled(*args)
      args[1]
    end

    def expire_cache_with_disabled(*args)
      true
    end

    def self.add_to(klass)
      return if klass.respond_to? :fetch_cache_with_disabled
      klass.extend self

      class << klass
        alias_method_chain :fetch_cache,  :disabled
        alias_method_chain :set_cache,    :disabled
        alias_method_chain :expire_cache, :disabled
      end

      class << CACHE
        include FragmentCache::DisabledExtensions
      end if ActsAsCached.config[:fragments] && defined?(FragmentCache::DisabledExtensions)
    end
  end
end
