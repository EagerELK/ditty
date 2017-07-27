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
      @components[name] = mod
    end

    def self.components
      @components
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
          puts "Loading #{component}"
          component = Components.load_component(component) if component.is_a?(Symbol)
          include(component::InstanceMethods) if defined?(component::InstanceMethods)
          extend(component::ClassMethods) if defined?(component::ClassMethods)
          component.configure(self, *args, &block) if component.respond_to?(:configure)

          nil
        end

        # Return a hash of controllers with their routes as keys: `{ '/users' => Ditty::Controllers::Users }`
        def routes
          Components.components.inject({}) do |memo, component|
            memo.merge!(component[1].routes) if component[1].respond_to?(:routes)
          end
        end

        # Return an ordered list of navigation items:
        # `[{order:0, link:'/users/', text:'Users'}, {order:1, link:'/roles/', text:'Roles'}]
        def navigation
          Components.components.map do |_key, component|
            component.navigation if component.respond_to?(:navigation)
          end.compact.flatten.sort_by { |h| h[:order] }
        end

        def migrations
          Components.components.map do |_key, component|
            component.migrations if component.respond_to?(:migrations)
          end.compact
        end

        def seeders
          Components.components.map do |_key, component|
            component.seeders if component.respond_to?(:seeders)
          end.compact
        end

        def workers
          Components.components.map do |_key, component|
            component.workers if component.respond_to?(:workers)
          end.compact
        end
      end

      module InstanceMethods
      end
    end
  end

  extend Components::Base::ClassMethods
  component Components::Base
end
