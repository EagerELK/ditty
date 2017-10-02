# frozen_string_literal: true

require 'sequel'
require 'ditty/services/logger'

# Delete DATABASE_URL from the environment, so it isn't accidently
# passed to subprocesses.  DATABASE_URL may contain passwords.
DB = Sequel.connect(ENV['RACK_ENV'] == 'production' ? ENV.delete('DATABASE_URL') : ENV['DATABASE_URL'])

log_level = (ENV['SEQUEL_LOGGING_LEVEL'] || :debug).to_sym
DB.sql_log_level = log_level
DB.loggers << Ditty::Services::Logger.instance
