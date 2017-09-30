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
      unless component = h[name]
        require "ditty/components/#{name}"
        raise ComponentError, "Component #{name} did not register itself correctly in Ditty::Components" unless component = h[name]
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
      @routes ||= {}
    end

    def self.routes=(routes)
      @routes = routes
    end

    # Return an ordered list of navigation items:
    # `[{order:0, link:'/users/', text:'Users'}, {order:1, link:'/roles/', text:'Roles'}]
    def self.navigation
      @navigation ||= {}
      @navigation.compact.flatten.sort_by { |h| h[:order] }
    end

    def self.navigation=(navigation)
      @navigation = navigation
    end

    def self.migrations
      @migrations ||= []
      @migrations.compact
    end

    def self.migrations=(migrations)
      @migrations = migrations
    end

    def self.seeders
      @seeders ||= []
      @seeders.compact
    end

    def self.seeders=(seeders)
      @seeders = seeders
    end

    def self.workers
      @workers ||= []
      @workers.compact
    end

    def self.workers=(workers)
      @workers = workers
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
          Components.navigation << component.navigation if component.respond_to?(:navigation)
          Components.routes.merge! component.routes if component.respond_to?(:routes)
          Components.migrations << component.migrations if component.respond_to?(:migrations)
          Components.seeders << component.seeder if component.respond_to?(:seeder)
          Components.workers << component.workers if component.respond_to?(:workers)

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
