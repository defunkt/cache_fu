class Memcached
  # A legacy compatibility wrapper for the Memcached class. It has basic compatibility with the <b>memcache-client</b> API.
  class Rails < ::Memcached
    def initialize(config)
      super(config.delete(:servers), config.slice(DEFAULTS.keys))
    end   

    def servers=(servers)
      
    end
    
    def delete(key, expiry = 0)
      super(key)
    rescue NotFound
    end
  end
end