# frozen_string_literal: true

require 'rake'
require 'ditty'
require 'ditty/components/ditty'

Ditty.component :ditty

Ditty::Components.tasks
require 'bundler/gem_tasks' if File.exist? 'ditty.gemspec'
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
end
