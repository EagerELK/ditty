# frozen_string_literal: true

require 'sequel'
require 'ditty/services/logger'
require 'active_support'
require 'active_support/core_ext/object/blank'

pool_timeout = ENV.fetch('DB_POOL_TIMEOUT', 5).to_i

if defined? DB
  ::Ditty::Services::Logger.warn '** Database connection already set up **'
elsif ENV.fetch('DATABASE_URL', nil)
  # Delete DATABASE_URL from the environment, so it isn't accidently
  # passed to subprocesses.  DATABASE_URL may contain passwords.
  DB = Sequel.connect(
    ENV.fetch('RACK_ENV', 'development') == 'production' ? ENV.delete('DATABASE_URL') : ENV.fetch('DATABASE_URL'),
    pool_timeout: pool_timeout
  )

  DB.sql_log_level = ENV.fetch('SEQUEL_LOGGING_LEVEL', :debug).to_sym
  DB.loggers << ::Ditty::Services::Logger if ENV.fetch('DB_DEBUG', 0).to_i == 1
  DB.extension(:pagination)
  DB.extension(:schema_caching)
  DB.load_schema_cache?('./config/schema.dump')

  Sequel::Model.plugin :auto_validations
  Sequel::Model.plugin :string_stripper
  Sequel::Model.plugin :timestamps, update_on_create: true
  Sequel::Model.plugin :update_or_create
  Sequel::Model.plugin :validation_helpers
else
  ::Ditty::Services::Logger.error '*** NO DATABASE CONNECTION SET UP ***'
end
