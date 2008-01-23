require File.join(File.dirname(__FILE__), 'helper')

ActsAsCached.config.clear
config = YAML.load_file(File.join(File.dirname(__FILE__), '../defaults/memcached.yml.default'))
config['test'] = config['development']
ActsAsCached.config = config
Story.send :acts_as_cached

context "When benchmarking is enabled" do
  specify "ActionController::Base should respond to rendering_runtime_with_memcache" do
    ActionController::Base.new.should.respond_to :rendering_runtime_with_memcache
  end

  specify "cachable Ruby classes should be respond to :logger" do
    Story.should.respond_to :logger
  end

  specify "a cached object should gain a fetch_cache with and without benchmarking methods" do
    Story.should.respond_to :fetch_cache_with_benchmarking
    Story.should.respond_to :fetch_cache_without_benchmarking
  end

  specify "cache_benchmark should yield and time any action" do
    ActsAsCached::Benchmarking.cache_runtime.should.equal 0.0

    level = Class.new { |k| def k.method_missing(*args) true end }
    Story.stubs(:logger).returns(level)

    Story.cache_benchmark("Seriously, nothing.", true) {
      sleep 0.01
     "Nothing."
    }.should.equal "Nothing."

    ActsAsCached::Benchmarking.cache_runtime.should.be > 0.0
  end
end
