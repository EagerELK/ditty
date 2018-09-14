# frozen_string_literal: true

require 'rake'
require 'bundler/gem_tasks'
Ditty::Components.tasks

require 'ditty'
require 'ditty/components/app'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
end
