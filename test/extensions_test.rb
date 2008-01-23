require File.join(File.dirname(__FILE__), 'helper')

module ActsAsCached
  module Extensions
    module ClassMethods
      def user_defined_class_method
        true
      end
    end

    module InstanceMethods
      def user_defined_instance_method
        true
      end
    end
  end
end

context "When Extensions::ClassMethods exists" do
  include StoryCacheSpecSetup

  specify "caching classes should extend it" do
    Story.singleton_methods.should.include 'user_defined_class_method'
  end
end

context "When Extensions::InstanceMethods exists" do
  include StoryCacheSpecSetup

  specify "caching classes should include it" do
    Story.instance_methods.should.include 'user_defined_instance_method'
  end
end
