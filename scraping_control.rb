require 'daemons'
require 'dotenv/load'

Daemons.run('scraping.rb')
