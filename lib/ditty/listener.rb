require 'wisper'

module Ditty
  class Listener
    def initialize
      @mutex = Mutex.new
    end

    def method_missing(method, *args)
      vals = { action: method }
      return super unless args[0].is_a? Hash
      vals[:user] = args[0][:user] if args_by_key(args, :user)
      vals[:details] = args[0][:details] if args_by_key(args, :details)
      @mutex.synchronize { AuditLog.create vals }
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end

    def args_by_key?(args, key)
      args[0] && args[0].key?(key)
    end
  end
end

Wisper.subscribe(Ditty::Listener.new)
