# frozen_string_literal: true

require 'sequel'
require 'ditty/services/logger'

if ENV['DATABASE_URL'].nil?
  Ditty::Services::Logger.instance.error 'No database connection set up'
  exit(false)
end

# Delete DATABASE_URL from the environment, so it isn't accidently
# passed to subprocesses.  DATABASE_URL may contain passwords.
DB = Sequel.connect(ENV['RACK_ENV'] == 'production' ? ENV.delete('DATABASE_URL') : ENV['DATABASE_URL'])

DB.sql_log_level = (ENV['SEQUEL_LOGGING_LEVEL'] || :debug).to_sym
DB.loggers << Ditty::Services::Logger.instance

Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :update_or_create
Sequel::Model.plugin :timestamps, update_on_create: true

DB.extension(:pagination)
