require 'sequel'
require 'ditty/db' unless defined? ::DB

module Ditty
  module Base
    def for_json
      values
    end
  end
end
