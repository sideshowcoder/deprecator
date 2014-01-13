require "test_helper"

describe "ensureing versions" do

  before do
    @subject = Class.new do
      attr_reader :version

      def initialize args
        args.each { |k, v| self.instance_variable_set "@#{k}", v }
      end

      include Deprecator::Versioning
    end
  end

  it "does nothing if the version matches" do
    @subject.instance_eval do
      ensure_version 2, :version_upgrade
      define_method(:version_upgrade) do |_|
        raise "version_upgrade should not be called"
      end
    end
    @subject.new(version: 2)
  end

  it "calls the upgrade_method on version mismatch" do
    @subject.instance_eval do
      ensure_version 2, :version_upgrade
      define_method(:version_upgrade) do |new_version|
        @version = new_version
      end
    end

    @subject.new(version: 1).version.must_equal 2
  end

  it "allows a lambda to be passed as the upgrade handler" do
    @subject.instance_eval do
      ensure_version 2, ->(new_version) { @version = new_version }
    end

    @subject.new(version: 1).version.must_equal 2
  end

  it "allows a block to be passed as the upgrade handler" do
    @subject.instance_eval do
      ensure_version(2) { |expected_version| @version = expected_version }
    end

    @subject.new(version: 1).version.must_equal 2
  end

end
