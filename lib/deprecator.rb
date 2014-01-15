require "deprecator/version"

module Deprecator

  def self.register_global_hook callback = nil, &block
    global_hooks << callback if callback
    global_hooks << block if block_given?
  end

  def self.reset_global_hooks!
    @global_hooks = []
  end

  def self.global_hooks
    @global_hooks ||= []
  end

  def self.run_global_hooks object, current_version, expected_version
    global_hooks.each do |hook|
      hook.call object, current_version, expected_version
    end
  end

  module Versioning
    def self.included base
      base.extend ClassMethods

      base.class_eval do
        base_initialize = instance_method(:initialize)
        define_method(:initialize) do |*args, &block|
          base_initialize.bind(self).call(*args, &block)
          version_hook
        end
      end
    end

    def version_hook
      self.class.__ensured.each do |expected_version, callbacks|
        if current_version < expected_version
          callbacks.each { |cb| run_version_callback cb, expected_version }
          Deprecator.run_global_hooks self, current_version, 2
        end
      end

      self.class.__matched.each do |expected_version, callbacks|
        if current_version != expected_version
          callbacks.each { |cb| run_version_callback cb, expected_version }
          Deprecator.run_global_hooks self, current_version, expected_version
        end
      end
    end

    private
    def run_version_callback cb, *args
      case cb
      when Proc
        self.instance_exec(*args, &cb)
      else
        self.send cb, *args
      end
    end

    def current_version
      self.send self.class.__version_property
    end

    module ClassMethods
      def ensure_version expected_version, upgrade_method = nil, &block
        if block_given?
          __ensured[expected_version] << block
        elsif upgrade_method
          __ensured[expected_version] << upgrade_method
        else
          # nothing is passed, register an noop to make sure global hooks are called
          noop = lambda { |_| }
          __ensured[expected_version] << noop
        end
      end

      def match_version expected_version, missmatch_method = nil, &block
        if block_given?
          __matched[expected_version] << block
        elsif missmatch_method
          __matched[expected_version] << missmatch_method
        else
          # nothing is passed, register an noop to make sure global hooks are called
          noop = lambda { |_| }
          __matched[expected_version] << noop
        end
      end

      def version_by property
        @__version_property = property
      end

      # Internal handling for storing the hook callbacks
      def __versions
        @__versions ||= {
          ensured: Hash.new { |hash, key| hash[key] = [] },
          matched: Hash.new { |hash, key| hash[key] = [] }
        }
      end

      def __version_property
        @__version_property ||= :version
      end

      def __ensured
        __versions[:ensured]
      end

      def __matched
        __versions[:matched]
      end
    end
  end
end
