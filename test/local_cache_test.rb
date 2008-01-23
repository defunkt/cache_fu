require File.join(File.dirname(__FILE__), 'helper')

context "When local_cache_for_request is called" do
  include StoryCacheSpecSetup

  setup do
    ActionController::Base.new.local_cache_for_request
    $cache = CACHE if $with_memcache
  end

  specify "get_cache should pull from the local cache on a second hit" do
    $cache.expects(:get).with('Story:2').returns(@story2)
    @story2.get_cache
    $cache.expects(:get).never
    @story2.get_cache
  end

  specify "set_cache should set to the local cache" do
    $cache.expects(:set).at_least_once.returns(@story)
    ActsAsCached::LocalCache.local_cache.expects(:[]=).with('Story:1', @story).returns(@story)
    @story.set_cache
  end

  specify "expire_cache should clear from the local cache" do
    @story2.get_cache
    $cache.expects(:delete).at_least_once
    ActsAsCached::LocalCache.local_cache.expects(:delete).with('Story:2')
    @story2.expire_cache
  end

  specify "clear_cache should clear from the local cache" do
    @story2.get_cache
    $cache.expects(:delete).at_least_once
    ActsAsCached::LocalCache.local_cache.expects(:delete).with('Story:2')
    @story2.clear_cache
  end

  specify "cached? should check the local cache" do
    @story2.get_cache
    $cache.expects(:get).never
    @story2.cached?
  end
end
