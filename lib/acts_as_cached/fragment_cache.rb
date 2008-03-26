module ActsAsCached
  module FragmentCache
    def self.setup!
      class << CACHE
        include Extensions
      end
      
      setup_fragment_cache_cache
      setup_rails_for_memcache_fragments
      setup_rails_for_action_cache_options
    end
    
    # add :ttl option to cache helper and set cache store memcache object
    def self.setup_rails_for_memcache_fragments
      if ::ActionView.const_defined?(:Template)
        # Rails 2.1+
        ::ActionController::Base.cache_store = CACHE
      else
        # Rails < svn r8619
        ::ActionView::Helpers::CacheHelper.class_eval do
          def cache(name = {}, options = nil, &block)
            @controller.cache_erb_fragment(block, name, options)
          end
        end
        ::ActionController::Base.fragment_cache_store = CACHE
      end
    end

    def self.setup_fragment_cache_cache
      Object.const_set(:FragmentCacheCache, Class.new { acts_as_cached :store => CACHE })
    end
    
    # add :ttl option to caches_action on the per action level by passing in a hash instead of an array
    # 
    # Examples:
    #  caches_action :index                                       # will use the default ttl from your memcache.yml, or 25 minutes
    #  caches_action :index => { :ttl => 5.minutes }              # cache index action with 5 minute ttl
    #  caches_action :page, :feed, :index => { :ttl => 2.hours }  # cache index action with 2 hours ttl, all others use default
    #
    def self.setup_rails_for_action_cache_options
      ::ActionController::Caching::Actions::ActionCacheFilter.class_eval do
        # convert all actions into a hash keyed by action named, with a value of a ttl hash (to match other cache APIs)
        def initialize(*actions, &block)
          if [].respond_to?(:extract_options!)
            #edge
            @options = actions.extract_options!
            @actions = actions.inject(@options.except(:cache_path)) do |hsh, action|
              action.is_a?(Hash) ? hsh.merge(action) : hsh.merge(action => { :ttl => nil })
            end
            @options.slice!(:cache_path)
          else
            #1.2.5
            @actions = actions.inject({}) do |hsh, action|
              action.is_a?(Hash) ? hsh.merge(action) : hsh.merge(action => { :ttl => nil })
            end
          end
        end

        # override to skip caching/rendering on evaluated if option
        def before(controller)
          return unless @actions.include?(controller.action_name.intern)

          # maintaining edge and 1.2.x compatibility with this branch
          if @options
            action_cache_path = ActionController::Caching::Actions::ActionCachePath.new(controller, path_options_for(controller, @options))
          else
            action_cache_path = ActionController::Caching::Actions::ActionCachePath.new(controller)
          end
          
          # should probably be like ActiveRecord::Validations.evaluate_condition.  color me lazy.
          if conditional = @actions[controller.action_name.intern][:if]
            conditional = conditional.respond_to?(:call) ? conditional.call(controller) : controller.send(conditional)
          end
          @actions.delete(controller.action_name.intern) if conditional == false

          cache = controller.read_fragment(action_cache_path.path)
          if cache && (conditional || conditional.nil?)
            controller.rendered_action_cache = true
            if method(:set_content_type!).arity == 2
              set_content_type!(controller, action_cache_path.extension)
            else
              set_content_type!(action_cache_path)
            end
            controller.send(:render, :text => cache)
            false
          else
            # 1.2.x compatibility
            controller.action_cache_path = action_cache_path if controller.respond_to? :action_cache_path
          end
        end
        
        # override to pass along the ttl hash
        def after(controller)
          return if !@actions.include?(controller.action_name.intern) || controller.rendered_action_cache
          # 1.2.x compatibility
          path = controller.respond_to?(:action_cache_path) ? controller.action_cache_path.path : ActionController::Caching::Actions::ActionCachePath.path_for(controller)
          controller.write_fragment(path, controller.response.body, action_ttl(controller))
        end

        private
        def action_ttl(controller)
          @actions[controller.action_name.intern]
        end
      end
    end

    module Extensions
      def read(*args)
        return if ActsAsCached.config[:skip_gets]
        FragmentCacheCache.cache_store(:get, args.first)
      end
      
      def write(name, content, options = {}) 
        ttl = (options.is_a?(Hash) ? options[:ttl] : nil) || ActsAsCached.config[:ttl] || 25.minutes
        FragmentCacheCache.cache_store(:set, name, content, ttl)
      end
    end

    module DisabledExtensions
      def read(*args) nil end
      def write(*args) "" end
    end
  end
end
