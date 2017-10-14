# frozen_string_literal: true

require 'ditty/version'

module Ditty
  class ComponentError < StandardError; end

  # A thread safe cache class, offering only #[] and #[]= methods,
  # each protected by a mutex.
  # Ripped off from Roda - https://github.com/jeremyevans/roda
  class ComponentCache
    # Create a new thread safe cache.
    def initialize
      @mutex = Mutex.new
      @hash = {}
    end

    # Make getting value from underlying hash thread safe.
    def [](key)
      @mutex.synchronize { @hash[key] }
    end

    # Make setting value in underlying hash thread safe.
    def []=(key, value)
      @mutex.synchronize { @hash[key] = value }
    end

    def map(&block)
      @mutex.synchronize { @hash.map(&block) }
    end

    def inject(memo, &block)
      @mutex.synchronize { @hash.inject(memo, &block) }
    end
  end

  # Ripped off from Roda - https://github.com/jeremyevans/roda
  module Components
    # Stores registered components
    @components = ComponentCache.new

    # If the registered component already exists, use it.  Otherwise,
    # require it and return it.  This raises a LoadError if such a
    # component doesn't exist, or a Component if it exists but it does
    # not register itself correctly.
    def self.load_component(name)
      h = @components
      unless (component = h[name])
        require "ditty/components/#{name}"
        raise ComponentError, "Component #{name} did not register itself correctly in Ditty::Components" unless (component = h[name])
      end
      component
    end

    # Register the given component with Component, so that it can be loaded using #component
    # with a symbol. Should be used by component files. Example:
    #
    #   Ditty::Components.register_component(:component_name, ComponentModule)
    def self.register_component(name, mod)
      puts "Registering #{mod} as #{name}"
      @components[name] = mod
    end

    def self.components
      @components
    end

    # Return a hash of controllers with their routes as keys: `{ '/users' => Ditty::Controllers::Users }`
    def self.routes
      components.inject({}) do |memo, comp|
        memo.merge! comp[1].routes if comp[1].respond_to?(:routes)
        memo
      end.compact
    end

    # Return an ordered list of navigation items:
    # `[{order:0, link:'/users/', text:'Users'}, {order:1, link:'/roles/', text:'Roles'}]
    def self.navigation
      components.inject([]) do |memo, comp|
        memo.concat comp[1].navigation if comp[1].respond_to?(:navigation)
        memo
      end.sort_by { |v| v[:order] }
    end

    def self.migrations
      components.map do |_name, comp|
        comp.migrations if comp.respond_to?(:migrations)
      end.compact
    end

    def self.seeders
      components.map do |_name, comp|
        comp.seeder if comp.respond_to?(:seeder)
      end.compact
    end

    def self.workers
      components.inject([]) do |memo, comp|
        memo.concat comp[1].workers if comp[1].respond_to?(:workers)
        memo
      end
    end

    module Base
      module ClassMethods
        # Load a new component into the current class.  A component can be a module
        # which is used directly, or a symbol represented a registered component
        # which will be required and then used. Returns nil.
        #
        #   Component.component ComponentModule
        #   Component.component :csrf
        def component(component, *args, &block)
          raise ComponentError, 'Cannot add a component to a frozen Component class' if frozen?
          component = Components.load_component(component) if component.is_a?(Symbol)
          include(component::InstanceMethods) if defined?(component::InstanceMethods)
          extend(component::ClassMethods) if defined?(component::ClassMethods)

          component.configure(self, *args, &block) if component.respond_to?(:configure)
          nil
        end
      end

      module InstanceMethods
      end
    end
  end

  extend Components::Base::ClassMethods
  component Components::Base
end
