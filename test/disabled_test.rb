require File.join(File.dirname(__FILE__), 'helper')

context "When the cache is disabled" do
  setup do
    @story  = Story.new(:id => 1, :title => "acts_as_cached 2 released!")
    @story2 = Story.new(:id => 2, :title => "BDD is something you can use")
    $stories = { 1 => @story, 2 => @story2 }

    config = YAML.load_file('defaults/memcached.yml.default')
    config['test'] = config['development'].merge('disabled' => true, 'benchmarking' => false)
    ActsAsCached.config = config
    Story.send :acts_as_cached
  end

  specify "get_cache should call through to the finder" do
    Story.expects(:find).at_least_once.returns(@story2)
    @story2.get_cache.should.equal @story2
  end

  specify "expire_cache should return true" do
    $cache.expects(:delete).never
    @story2.expire_cache.should.equal true
  end

  specify "reset_cache should return the object" do
    $cache.expects(:set).never
    Story.expects(:find).at_least_once.returns(@story2)
    @story2.reset_cache.should.equal @story2
  end
  
  specify "set_cache should just return the object" do
    $cache.expects(:set).never
    @story2.set_cache.should.equal @story2
  end

  specify "cached? should return false" do
    $cache.expects(:get).never
    @story2.should.not.be.cached
  end
end
