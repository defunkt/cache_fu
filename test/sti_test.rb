require File.join(File.dirname(__FILE__), 'helper')

context "An STI subclass acting as cached" do
  include StoryCacheSpecSetup

  setup do
    @feature   = Feature.new(:id => 3, :title => 'Behind the scenes of acts_as_cached')
    @interview = Interview.new(:id => 4, :title => 'An interview with the Arcade Fire')
    @feature.expire_cache
    @interview.expire_cache
    $stories.update 3 => @feature, 4 => @interview
  end

  specify "should be just as retrievable as any other cachable Ruby object" do
    Feature.cached?(3).should.equal false
    Feature.get_cache(3)
    Feature.cached?(3).should.equal true
  end

  specify "should have a key corresponding to its parent class" do
    @feature.cache_key.should.equal "Story:3"
    @interview.cache_key.should.equal "Story:4"
  end

  specify "should be able to get itself from the cache via its parent class" do
    Story.get_cache(3).should.equal @feature
    Story.get_cache(4).should.equal @interview
  end

  specify "should take on its parents cache options but be able to set its own" do
    @feature.cache_key.should.equal "Story:3"
    Feature.cache_config[:version] = 1
    @feature.cache_key.should.equal "Story:1:3"
    @story.cache_key.should.equal "Story:1"
  end
end
