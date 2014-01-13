require "deprecator/version"

module Deprecator
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
        if version < expected_version
          callbacks.each { |cb| run_callback cb, expected_version }
        end
      end
    end

    private
    def run_callback cb, *args
      case cb
      when Proc
        self.instance_exec(*args, &cb)
      else
        self.send cb, *args
      end
    end

    module ClassMethods
      attr_reader :__ensured

      def ensure_version expected_version, upgrade_method = nil, &block
        @__ensured ||= Hash.new { |hash, key| hash[key] = [] }
        @__ensured[expected_version] << block if block_given?
        @__ensured[expected_version] << upgrade_method if upgrade_method
      end
    end
  end
end
