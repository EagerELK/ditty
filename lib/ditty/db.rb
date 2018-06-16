# frozen_string_literal: true

require 'sequel'
require 'ditty/services/logger'
require 'active_support'
require 'active_support/core_ext/object/blank'

pool_timeout = (ENV['DB_POOL_TIMEOUT'] || 5).to_i

if defined? DB
  Ditty::Services::Logger.instance.warn 'Database connection already set up'
elsif ENV['DATABASE_URL'].blank? == false
  # Delete DATABASE_URL from the environment, so it isn't accidently
  # passed to subprocesses.  DATABASE_URL may contain passwords.
  DB = Sequel.connect(
    ENV['RACK_ENV'] == 'production' ? ENV.delete('DATABASE_URL') : ENV['DATABASE_URL'],
    pool_timeout: pool_timeout
  )

  DB.sql_log_level = (ENV['SEQUEL_LOGGING_LEVEL'] || :debug).to_sym
  DB.loggers << Ditty::Services::Logger.instance
  DB.extension(:pagination)

  Sequel::Model.plugin :validation_helpers
  Sequel::Model.plugin :update_or_create
  Sequel::Model.plugin :timestamps, update_on_create: true
else
  Ditty::Services::Logger.instance.error 'No database connection set up'
end
