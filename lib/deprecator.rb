require "deprecator/version"

module Deprecator
  # = Add data version handling to a ruby object
  #
  # Deprecator adds implicit calls to upgrade methods in case of a +version+
  # missmatch for a given object. The missmatch is defined as that the
  # +@version+ property of a given object does not match the specified ones
  #
  #   class Thing
  #     def initialize version
  #       @version = version
  #     end
  #
  #     include Deprecator::Versioning
  #     ensure_version 2 do |expected|
  #        puts "Missmatch: #{expected} was expected, #{version} given for #{self}"
  #     end
  #   end
  #
  # == Caveat
  # It works by hooking initialize so it must be included after an initialize
  # method is defined


  ##
  # Register a global hook to be called on any version missmatch
  # either pass a lambda or a block to be executed
  def self.register_global_hook callback = nil, &block
    global_hooks << callback if callback
    global_hooks << block if block_given?
  end

  ##
  # Delete all registerd version hooks
  def self.reset_global_hooks!
    @global_hooks = []
  end

  ##
  # Show current registerd hooks
  def self.global_hooks
    @global_hooks ||= []
  end

  ##
  # Run each global hook with the passed parameters
  # This is called automatically on version missmatch by the missmatched object
  def self.run_global_hooks object, current_version, expected_version
    global_hooks.each do |hook|
      hook.call object, current_version, expected_version
    end
  end

  module Versioning
    # = Deprecator::Versioning
    #
    # handle the core versioning logic

    ##
    # Included callback
    # hooks the initialize method for a given object
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

    ##
    # Versioning logic
    # Run any registerd hooks, as well as global hooks as needed
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

      ##
      # ensure an object is at a given version
      # registers a callback to be called if the current object version is less
      # than the one ensured.
      # The callback can either be a lambda, block or symbol to reference a
      # method on the object.
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

      ##
      # ensure an object has a certain version registers a callback to be
      # called if the current object version is not exactly than the one
      # matched.
      # The callback can either be a lambda, block or symbol to reference a
      # method on the object.
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

      ##
      # Specify which object property should be used to determine the version
      def version_by property
        @__version_property = property
      end

      ##
      # Private: Internal handling for storing the hook callbacks
      def __versions
        @__versions ||= {
          ensured: Hash.new { |hash, key| hash[key] = [] },
          matched: Hash.new { |hash, key| hash[key] = [] }
        }
      end

      ##
      # Private: reference to the version property
      def __version_property
        @__version_property ||= :version
      end

      ##
      # Private: reference to the ensured versions
      def __ensured
        __versions[:ensured]
      end

      ##
      # Private: reference to the matched versions
      def __matched
        __versions[:matched]
      end
    end
  end
end
