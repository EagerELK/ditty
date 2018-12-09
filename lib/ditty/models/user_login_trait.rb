# frozen_string_literal: true

require 'ditty/models/base'

# Why not store this in Elasticsearch?
module Ditty
  class UserLoginTrait < ::Sequel::Model
    include ::Ditty::Base

    many_to_one :user

    def validate
      super
    end
  end
end
