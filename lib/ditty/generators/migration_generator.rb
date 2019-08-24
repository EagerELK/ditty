# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'

module Ditty
  module Generators
    class MigrationGenerator < Thor::Group
      include Thor::Actions

      attr_reader :namespace, :folder

      desc 'Creates a new Sequel migration for the current project'
      argument :name, type: :string, desc: 'Name of the migration'

      def self.source_root
        File.expand_path('../templates', __dir__)
      end

      def create_model
        filename = File.join('migrations', "#{Time.now.strftime('%Y%m%d')}_#{name.underscore}.rb")
        template '../templates/migration.rb.erb', filename
      end
    end
  end
end
