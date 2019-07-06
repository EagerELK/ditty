# frozen_string_literal: true

require 'rubocop'
require 'rubocop/ast/node'
require 'rubocop/cop/cop'

module RuboCop
  module Cop
    module Ditty
      # This cop enforces the use of `Service.method` instead of
      # `Service.instance.method`. Calling the singleton instance has been
      # deprecated for services.
      #
      # @example
      #   # bad
      #   ::Ditty::Services::Logger.instance.info 'This is a log message'
      #
      #   # good
      #   ::Ditty::Services::Logger.info 'This is a log message'
      class CallServicesDirectly < RuboCop::Cop::Cop
        MSG = 'Do not use `.instance` on services. Call the method directly instead'

        def_node_matcher :service_instance_call?, <<-PATTERN
          (send (const (const (const ... :Ditty) :Services) _) :instance)
        PATTERN

        def on_send(node)
          return unless service_instance_call?(node)

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            internal = node.children.first.source
            corrector.replace(node.loc.expression, internal)
          end
        end
      end
    end
  end
end
