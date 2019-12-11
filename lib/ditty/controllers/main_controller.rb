# frozen_string_literal: true

require 'ditty/controllers/application_controller'
require 'ditty/models/role'
require 'ditty/models/user'
require 'ditty/services/settings'

module Ditty
  class MainController < ApplicationController
    set track_actions: true

    before '/' do
      return if User.where(roles: Role.find_or_create(name: 'super_admin')).count.positive?

      flash[:info] = 'Please register the super admin user.'
      redirect "#{settings.map_path}/auth/register"
    end

    # Home Page
    get '/' do
      home_page = Services::Settings['ditty.home_page']
      redirect "#{settings.map_path}#{home_page}" if home_page

      authenticate!
      haml :index, locals: { title: 'Home' }
    end
  end
end
