# frozen_string_literal: true

require 'ditty/controllers/application'
require 'ditty/models/role'
require 'ditty/models/user'

module Ditty
  class Main < Application
    set track_actions: true

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Basic Plugin
    end

    before '/' do
      return if User.where(roles: Role.find_or_create(name: 'super_admin')).count.positive?
      flash[:info] = 'Please register the super admin user.'
      redirect "#{settings.map_path}/auth/register"
    end

    # Home Page
    get '/' do
      authenticate!
      haml :index, locals: { title: 'Home' }
    end
  end
end
