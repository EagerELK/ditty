require 'sequel'

module Ditty
  module Base
    def for_json
      values
    end

    alias for_csv for_json
  end
end
