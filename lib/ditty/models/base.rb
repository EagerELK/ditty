# frozen_string_literal: true

require 'digest/sha2'
require 'sequel'

module Ditty
  module Base
    def for_json
      values
    end

    def display_id
      self[:slug] || self[:guid] || self[:id]
    end

    def etag
      Digest::SHA2.hexdigest values.to_json
    end

    alias for_csv for_json
  end
end
