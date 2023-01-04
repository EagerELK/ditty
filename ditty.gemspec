# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ditty/version'

Gem::Specification.new do |spec|
  spec.name          = 'ditty'
  spec.version       = ::Ditty::VERSION
  spec.authors       = ['Jurgens du Toit']
  spec.email         = ['jrgns@jadeit.co.za']

  spec.summary       = 'Sinatra Based Application Framework'
  spec.description   = 'Sinatra Based Application Framework'
  spec.homepage      = 'https://github.com/eagerelk/ditty'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0") #.reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = ['ditty']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'database_cleaner', '~> 1.0'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'racksh'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rubocop-sequel'
  spec.add_development_dependency 'rubocop-thread_safety'
  spec.add_development_dependency 'simplecov', '~> 0.13.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop'

  spec.add_dependency 'activesupport', '>= 6'
  spec.add_dependency 'bcrypt', '>= 3.1'
  spec.add_dependency 'browser', '>= 5.3'
  spec.add_dependency 'dotenv', '>= 2'
  spec.add_dependency 'haml', '~> 5.1', '>= 5.1.2'
  spec.add_dependency 'logger', '>= 1.0'
  spec.add_dependency 'mail', '>= 1.7'
  spec.add_dependency 'oga', '>= 2.14'
  spec.add_dependency 'omniauth', '>= 1.0'
  spec.add_dependency 'omniauth-identity', '>= 1.0'
  spec.add_dependency 'pundit', '>= 2.0'
  spec.add_dependency 'rack-contrib', '>= 2.0'
  spec.add_dependency 'rack_csrf', '>= 2.0'
  spec.add_dependency 'rake', '>= 13.0'
  spec.add_dependency 'sequel', '>= 5.0'
  spec.add_dependency 'sinatra', '>= 2.1'
  spec.add_dependency 'sinatra-contrib', '>= 2.0'
  spec.add_dependency 'sinatra-flash', '>= 0.3'
  spec.add_dependency 'sinatra-param', '>= 1.6'
  spec.add_dependency 'thor', '>= 0.20'
  spec.add_dependency 'tilt', '>= 2'
  spec.add_dependency 'will_paginate', '>= 3.1'
  spec.add_dependency 'wisper', '>= 2.0'
end
