# frozen_string_literal: true

require 'sequel'

module Ditty
  module Base
    def for_json
      values
    end

    def display_id
      self[:slug] || self[:guid] || self[:id]
    end

    alias for_csv for_json
  end
end
