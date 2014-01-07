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
      self.class.__ensured.each { |expected_version, callbacks|
        if version < expected_version
          callbacks.each { |cb| self.send cb, expected_version }
        end
      }
    end

    module ClassMethods
      attr_reader :__ensured

      def ensure_version expected_version, upgrade_method
        @__ensured ||= Hash.new { |hash, key| hash[key] = [] }
        @__ensured[expected_version] << upgrade_method
      end
    end
  end
end
