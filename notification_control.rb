require 'daemons'
require 'dotenv/load'

Daemons.run('notification.rb')
