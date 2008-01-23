require File.join(File.dirname(__FILE__), 'helper')

context "A Ruby class acting as cached (in general)" do
  include StoryCacheSpecSetup

  specify "should be able to retrieve a cached instance from the cache" do
    Story.get_cache(1).should.equal Story.find(1)
  end

  specify "should set to the cache if its not already set when getting" do
    Story.should.not.have.cached 1
    Story.get_cache(1).should.equal Story.find(1)
    Story.should.have.cached 1
  end

  specify "should not set to the cache if is already set when getting" do
    Story.expects(:set_cache).never
    Story.should.have.cached 2
    Story.get_cache(2).should.equal Story.find(2)
    Story.should.have.cached 2
  end

  specify "should be able to tell if a key is cached" do
    Story.is_cached?(1).should.equal false
    Story.should.not.have.cached 1
    Story.should.have.cached 2
  end

  specify "should be able to cache arbitrary methods using #caches" do
    Story.cache_store.expects(:get).returns(nil)
    Story.cache_store.expects(:set).with('Story:something_cool', :redbull, 1500)
    Story.caches(:something_cool).should.equal :redbull

    Story.cache_store.expects(:get).returns(:redbull)
    Story.cache_store.expects(:set).never
    Story.caches(:something_cool).should.equal :redbull
  end

  specify "should be able to cache arbitrary methods with arguments using #caches and :with" do
    with = :mongrel

    Story.cache_store.expects(:get).returns(nil)
    Story.cache_store.expects(:set).with("Story:block_on:#{with}", with, 1500)
    Story.caches(:block_on, :with => with).should.equal with

    Story.cache_store.expects(:get).with("Story:block_on:#{with}").returns(:okay)
    Story.cache_store.expects(:set).never
    Story.caches(:block_on, :with => with).should.equal :okay
  end

  specify "should be able to cache arbitrary methods with a nil argument using #caches and :with" do
    with = nil

    Story.cache_store.expects(:get).returns(nil)
    Story.cache_store.expects(:set).with("Story:pass_through:#{with}", :_nil, 1500)
    Story.caches(:pass_through, :with => with).should.equal with
  end

  specify "should be able to cache arbitrary methods with arguments using #caches and :withs" do
    withs = [ :first, :second ] 

    cached_string = "first: #{withs.first} | second: #{withs.last}"

    Story.cache_store.expects(:get).returns(nil)
    Story.cache_store.expects(:set).with("Story:two_params:#{withs}", cached_string, 1500)
    Story.caches(:two_params, :withs => withs).should.equal cached_string

    Story.cache_store.expects(:get).with("Story:two_params:#{withs}").returns(:okay)
    Story.cache_store.expects(:set).never
    Story.caches(:two_params, :withs => withs).should.equal :okay
  end

  specify "should set nil when trying to set nil" do
    Story.set_cache(3, nil).should.equal nil
    Story.get_cache(3).should.equal nil
  end

  specify "should set false when trying to set false" do
    Story.set_cache(3, false).should.equal false
    Story.get_cache(3).should.equal false
  end

  specify "should be able to expire a cache key" do
    Story.should.have.cached 2
    Story.expire_cache(2).should.equal true
    Story.should.not.have.cached 2
  end

  specify "should return true when trying to expire the cache" do
    Story.should.not.have.cached 1
    Story.expire_cache(1).should.equal true
    Story.should.have.cached 2
    Story.expire_cache(2).should.equal true
  end

  specify "should be able to reset a cache key, returning the cached object if successful" do
    Story.expects(:find).with(2).returns(@story2)
    Story.should.have.cached 2
    Story.reset_cache(2).should.equal @story2
    Story.should.have.cached 2
  end

  specify "should be able to cache the value of a block" do
    Story.should.not.have.cached :block
    Story.get_cache(:block) { "this is a block" }
    Story.should.have.cached :block
    Story.get_cache(:block).should.equal "this is a block"
  end

  specify "should be able to define a class level ttl" do
    ttl = 1124
    Story.cache_config[:ttl] = ttl
    Story.cache_config[:store].expects(:set).with(Story.cache_key(1), @story, ttl)
    Story.get_cache(1)
  end

  specify "should be able to define a per-key ttl" do
    ttl = 3262
    Story.cache_config[:store].expects(:set).with(Story.cache_key(1), @story, ttl)
    Story.get_cache(1, :ttl => ttl)
  end

  specify "should be able to skip cache gets" do
    Story.should.have.cached 2
    ActsAsCached.skip_cache_gets = true
    Story.expects(:find).at_least_once
    Story.get_cache(2)
    ActsAsCached.skip_cache_gets = false
  end

  specify "should be able to use an arbitrary finder method via :finder" do
    Story.expire_cache(4)
    Story.cache_config[:finder] = :find_live
    Story.expects(:find_live).with(4).returns(false)
    Story.get_cache(4)
  end

  specify "should raise an exception if no finder method is found" do
    Story.cache_config[:finder] = :find_penguins
    proc { Story.get_cache(1) }.should.raise(NoMethodError)
  end

  specify "should be able to use an abitrary cache_id method via :cache_id" do
    Story.expire_cache(4)
    Story.cache_config[:cache_id] = :title
    story = Story.get_cache(1)
    story.cache_id.should.equal story.title
  end

  specify "should modify its cache key to reflect a :version option" do
    Story.cache_config[:version] = 'new' 
    Story.cache_key(1).should.equal 'Story:new:1'
  end
  
  specify "should truncate the key normally if we dont have a namespace" do
    Story.stubs(:cache_namespace).returns(nil)
    key = "a" * 260
    Story.cache_key(key).length.should == 250
  end
  
  specify "should truncate key with length over 250, including namespace if set" do
    Story.stubs(:cache_namespace).returns("37-power-moves-app" )
    key = "a" * 260
    (Story.cache_namespace + Story.cache_key(key)).length.should == (250 - 1)
  end

  specify "should raise an informative error message when trying to set_cache with a proc" do
    Story.cache_config[:store].expects(:set).raises(TypeError.new("Can't marshal Proc"))
    proc { Story.set_cache('proc:d', proc { nil }) }.should.raise(ActsAsCached::MarshalError)
  end
end

context "Passing an array of ids to get_cache" do
  include StoryCacheSpecSetup

  setup do
    @grab_stories = proc do 
      @stories = Story.get_cache(1, 2, 3)
    end 

    @keys = 'Story:1', 'Story:2', 'Story:3'
    @hash = {
      'Story:1' => nil,
      'Story:2' => $stories[2],
      'Story:3' => nil
    }

    # TODO: doh, probably need to clean this up...
    @cache = $with_memcache ? CACHE : $cache

    @cache.expects(:get_multi).with(*@keys).returns(@hash)
  end

  specify "should try to fetch those ids using get_multi" do
    @grab_stories.call

    @stories.size.should.equal 3
    @stories.should.be.an.instance_of Hash
    @stories.each { |id, story| story.should.be.an.instance_of Story }
  end

  specify "should pass the cache miss ids to #find" do
    Story.expects(:find).with(%w(1 3)).returns($stories[1], $stories[3])
    @grab_stories.call
  end
end

context "Passing an array of ids to get_cache using a cache which doesn't support get_multi" do
  include StoryCacheSpecSetup

  setup do
    @grab_stories = proc do 
      @stories = Story.get_cache(1, 2, 3)
    end 

    # TODO: doh, probably need to clean this up...
    @cache = $with_memcache ? CACHE : $cache
  end

  specify "should raise an exception" do
    class << @cache; undef :get_multi end
    proc { @grab_stories.call }.should.raise(ActsAsCached::NoGetMulti)
  end
end

context "A Ruby object acting as cached" do
  include StoryCacheSpecSetup

  specify "should be able to retrieve a cached version of itself" do
    Story.expects(:get_cache).with(1, {}).at_least_once
    @story.get_cache
  end

  specify "should be able to set itself to the cache" do
    Story.expects(:set_cache).with(1, @story, nil).at_least_once
    @story.set_cache
  end

  specify "should cache the value of a passed block" do
    @story.should.not.have.cached :block
    @story.get_cache(:block) { "this is a block" }
    @story.should.have.cached :block
    @story.get_cache(:block).should.equal "this is a block"
  end
  
  specify "should allow setting custom options by passing them to get_cache" do
    Story.expects(:set_cache).with('1:options', 'cached value', 1.hour)
    @story.get_cache(:options, :ttl => 1.hour) { 'cached value' }
  end

  specify "should be able to expire its cache" do
    Story.expects(:expire_cache).with(2)
    @story2.expire_cache
  end

  specify "should be able to reset its cache" do
    Story.expects(:reset_cache).with(2)
    @story2.reset_cache
  end

  specify "should be able to tell if it is cached" do
    @story.should.not.be.cached
    @story2.should.be.cached
  end

  specify "should be able to set itself to the cache with an arbitrary ttl" do
    ttl = 1500
    Story.expects(:set_cache).with(1, @story, ttl)
    @story.set_cache(ttl)
  end

  specify "should be able to cache arbitrary instance methods using caches" do
    Story.cache_store.expects(:get).returns(nil)
    Story.cache_store.expects(:set).with('Story:1:something_flashy', :molassy, 1500)
    @story.caches(:something_flashy).should.equal :molassy

    Story.cache_store.expects(:get).returns(:molassy)
    Story.cache_store.expects(:set).never
    @story.caches(:something_flashy).should.equal :molassy
  end
end
