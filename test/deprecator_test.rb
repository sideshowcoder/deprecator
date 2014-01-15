require "test_helper"

describe Deprecator::Versioning do
  subject do
    Class.new do
      attr_reader :version

      def initialize args
        args.each { |k, v| self.instance_variable_set "@#{k}", v }
      end

      include Deprecator::Versioning
    end
  end

  describe "#ensure_version" do
    it "does nothing if the version matches" do
      subject.instance_eval do
        ensure_version 2, :version_upgrade
        define_method(:version_upgrade) do |_|
          raise "version_upgrade should not be called"
        end
      end
      subject.new(version: 2)
    end

    it "calls the upgrade_method on version mismatch" do
      subject.instance_eval do
        ensure_version 2, :version_upgrade
        define_method(:version_upgrade) do |new_version|
          @version = new_version
        end
      end

      subject.new(version: 1).version.must_equal 2
    end

    it "allows a lambda to be passed as the upgrade handler" do
      subject.instance_eval do
        ensure_version 2, ->(new_version) { @version = new_version }
      end

      subject.new(version: 1).version.must_equal 2
    end

    it "allows a block to be passed as the upgrade handler" do
      subject.instance_eval do
        ensure_version(2) { |expected_version| @version = expected_version }
      end

      subject.new(version: 1).version.must_equal 2
    end

  end

  describe "#match_version" do
    it "does nothting if the version matches" do
      subject.instance_eval do
        match_version 2, :missmatch
        define_method(:missmatch) { raise "should not call missmatch" }
      end
      subject.new(version: 2)
    end

    it "call the missmatch handler if version is does not match" do
      subject.instance_eval do
        match_version 2, :missmatch
        define_method(:missmatch) { |expected_version| @version = expected_version }
      end
      subject.new(version: 1).version.must_equal 2
      subject.new(version: 3).version.must_equal 2
    end
  end

  describe "#version_by" do
    before do
      subject.instance_eval do
        attr_reader :called
        ensure_version 2, :version_upgrade
        define_method(:version_upgrade) { |_| @called = true }
      end
    end

    it "allows versioning by a custom property" do
      subject.instance_eval do
        attr_accessor :my_version
        version_by :my_version
      end
      # pass both version an my_version with a matching version so we can be
      # sure that the call does not happen because of an unset default version
      # property
      subject.new(version: 2, my_version: 1).called.must_equal true
    end
  end
end
