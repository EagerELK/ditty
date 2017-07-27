# frozen_string_literal: true

require 'ditty/components/app/models/base'

module Ditty
  class Role < Sequel::Model
    include ::Ditty::Base

    many_to_many :users

    def validate
      validates_presence [:name]
      validates_unique [:name]
    end
  end
end
