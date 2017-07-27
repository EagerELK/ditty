require 'ditty/db'
require 'ditty/models/role'

::Ditty.seeders.each(&:call)
