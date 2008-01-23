require File.join(File.dirname(__FILE__), 'helper')
require 'test/unit'
require 'action_controller/test_process'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class FooController < ActionController::Base
  def url_for(*args)
    "http://#{Time.now.to_i}.foo.com"
  end
end

class BarController < ActionController::Base
  def page
    render :text => "give me my bongos"
  end
  
  def index
    render :text => "doop!"
  end
  
  def edit
    render :text => "rawk"
  end

  def trees_are_swell?
    true
  end

  def rescue_action(e)
    raise e
  end
end

class FooTemplate
  include ::ActionView::Helpers::CacheHelper
  
  attr_reader :controller

  def initialize
    @controller = FooController.new
  end
end

context "Fragment caching (when used with memcached)" do
  include FragmentCacheSpecSetup
  
  setup do
    @view = FooTemplate.new
  end
  
  specify "should be able to cache with a normal, non-keyed Rails cache calls" do
    _erbout = ""
    content = "Caching is fun!"

    ActsAsCached.config[:store].expects(:set).with(@view.controller.url_for.gsub('http://',''), content, ActsAsCached.config[:ttl])

    @view.cache { _erbout << content }
  end
  
  specify "should be able to cache with a normal cache call when we don't have a default ttl" do
    begin
      _erbout = ""
      content = "Caching is fun!"
    
      original_ttl = ActsAsCached.config.delete(:ttl)
      ActsAsCached.config[:store].expects(:set).with(@view.controller.url_for.gsub('http://',''), content, 25.minutes)

      @view.cache { _erbout << content }
    ensure
      ActsAsCached.config[:ttl] = original_ttl
    end
  end

  specify "should be able to cache with a normal, keyed Rails cache calls" do
    _erbout = ""
    content = "Wow, even a key?!"
    key = "#{Time.now.to_i}_wow_key"

    ActsAsCached.config[:store].expects(:set).with(key, content, ActsAsCached.config[:ttl])

    @view.cache(key) { _erbout << content } 
  end
  
  specify "should be able to cache with new time-to-live option" do 
    _erbout = ""
    content = "Time to live?  TIME TO DIE!!"
    key = "#{Time.now.to_i}_death_key"

    ActsAsCached.config[:store].expects(:set).with(key, content, 60)
    @view.cache(key, { :ttl => 60 }) { _erbout << content }
  end

  specify "should ignore everything but time-to-live when options are present" do 
    _erbout = ""
    content = "Don't mess around, here, sir."
    key = "#{Time.now.to_i}_mess_key"

    ActsAsCached.config[:store].expects(:set).with(key, content, 60)
    @view.cache(key, { :other_options => "for the kids", :ttl => 60 }) { _erbout << content } 
  end
  
  specify "should be able to skip cache gets" do
    ActsAsCached.skip_cache_gets = true
    ActsAsCached.config[:store].expects(:get).never
    _erbout = ""
    @view.cache { _erbout << "Caching is fun!" }
    ActsAsCached.skip_cache_gets = false
  end
end

context "Action caching (when used with memcached)" do
  include FragmentCacheSpecSetup
  page_content = "give me my bongos"
  index_content = "doop!"
  edit_content = "rawk"
  
  setup do
    @controller = BarController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  teardown do # clear the filter chain between specs to avoid chaos
    BarController.write_inheritable_attribute('filter_chain', [])
  end
  
  # little helper for prettier expections on the cache
  def cache_expects(method, expected_times = 1)
    ActsAsCached.config[:store].expects(method).times(expected_times)
  end

  specify "should cache using default ttl for a normal action cache without ttl" do
    BarController.caches_action :page

    key = 'test.host/bar/page'
    cache_expects(:set).with(key, page_content, ActsAsCached.config[:ttl])
    get :page
    @response.body.should == page_content
    
    cache_expects(:read).with(key, nil).returns(page_content)
    get :page
    @response.body.should == page_content
  end
  
  specify "should cache using defaul ttl for normal, multiple action caches" do
    BarController.caches_action :page, :index
    
    cache_expects(:set).with('test.host/bar/page', page_content, ActsAsCached.config[:ttl])
    get :page
    cache_expects(:set).with('test.host/bar', index_content, ActsAsCached.config[:ttl])
    get :index
  end
  
  specify "should be able to action cache with ttl" do
    BarController.caches_action :page => { :ttl => 2.minutes }

    cache_expects(:set).with('test.host/bar/page', page_content, 2.minutes)
    get :page
    @response.body.should == page_content
  end
  
  specify "should be able to action cache multiple actions with ttls" do
    BarController.caches_action :index, :page => { :ttl => 5.minutes }
    
    cache_expects(:set).with('test.host/bar/page', page_content, 5.minutes)
    cache_expects(:set).with('test.host/bar', index_content, ActsAsCached.config[:ttl])
    
    get :page
    @response.body.should == page_content

    get :index
    @response.body.should == index_content
    cache_expects(:read).with('test.host/bar', nil).returns(index_content)

    get :index
  end

  specify "should be able to action cache conditionally when passed something that returns true" do
    BarController.caches_action :page => { :if => :trees_are_swell? }
    
    cache_expects(:set).with('test.host/bar/page', page_content, ActsAsCached.config[:ttl])
    
    get :page
    @response.body.should == page_content

    cache_expects(:read).with('test.host/bar/page', nil).returns(page_content)

    get :page
  end

  #check for edginess
  if [].respond_to?(:extract_options!)
    specify "should not break cache_path overrides" do
      BarController.caches_action :page, :cache_path => 'http://test.host/some/custom/path'
      cache_expects(:set).with('test.host/some/custom/path', page_content, ActsAsCached.config[:ttl])
      get :page
    end
  
    specify "should not break cache_path block overrides" do
      BarController.caches_action :edit, :cache_path => Proc.new { |c| c.params[:id] ? "http://test.host/#{c.params[:id]}/edit" : "http://test.host/edit" }
      cache_expects(:set).with('test.host/edit', edit_content, ActsAsCached.config[:ttl])
      get :edit

      get :index
      cache_expects(:set).with('test.host/5/edit', edit_content, ActsAsCached.config[:ttl])
      get :edit, :id => 5
    end
  
    specify "should play nice with custom ttls and cache_path overrides" do 
      BarController.caches_action :page => { :ttl => 5.days }, :cache_path => 'http://test.host/my/custom/path'
      cache_expects(:set).with('test.host/my/custom/path', page_content, 5.days)
      get :page
    end
  
    specify "should play nice with custom ttls and cache_path block overrides" do 
      BarController.caches_action :edit, :cache_path => Proc.new { |c| c.params[:id] ? "http://test.host/#{c.params[:id]}/edit" : "http://test.host/edit" }
      cache_expects(:set).with('test.host/5/edit', edit_content, ActsAsCached.config[:ttl])
      get :edit, :id => 5
    end
    
    specify "should play nice with the most complicated thing i can throw at it" do 
      BarController.caches_action :index => { :ttl => 24.hours }, :page => { :ttl => 5.seconds }, :edit => { :ttl => 5.days }, :cache_path => Proc.new { |c| c.params[:id] ? "http://test.host/#{c.params[:id]}/#{c.params[:action]}" : "http://test.host/#{c.params[:action]}" }
      cache_expects(:set).with('test.host/index', index_content, 24.hours)
      get :index
      cache_expects(:set).with('test.host/5/edit', edit_content, 5.days)
      get :edit, :id => 5
      cache_expects(:set).with('test.host/5/page', page_content, 5.seconds)
      get :page, :id => 5
      
      cache_expects(:read).with('test.host/5/page', nil).returns(page_content)
      get :page, :id => 5
      cache_expects(:read).with('test.host/5/edit', nil).returns(edit_content)
      get :edit, :id => 5
      cache_expects(:read).with('test.host/index', nil).returns(index_content)
      get :index
    end
  end

  specify "should be able to skip action caching when passed something that returns false" do
    BarController.caches_action :page => { :if => Proc.new {|c| !c.trees_are_swell?} }
    
    cache_expects(:set, 0).with('test.host/bar/page', page_content, ActsAsCached.config[:ttl])
    
    get :page
    @response.body.should == page_content
  end
end
