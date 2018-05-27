require 'rubygems'
require 'dotenv/load'
require 'mysql2'
require 'mechanize'

# Define Database Connection
client = Mysql2::Client.new(
  host: ENV['DB_HOST'],
  username: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD'],
  database: ENV['DB_NAME']
)

URL_LIST = ['http://your-url.com']

loop do
  agent = Mechanize.new
  agent.user_agent_alias = 'Windows Mozilla'

  URL_LIST.each do |url|
    agent.add_auth(url, ENV['USERNAME'], ENV['PASSWORD'])
    agent.get(url) do |page|
      user = page.search('#cbi-table-1-user').first.children.text
      elapsed = page.search('#ant_elapsed').first.children.text
      ghsav = page.search('#ant_ghsav').first.children.text

      elements = page.search('#cbi-table-1-temp2')
      elements.each do |value|
        temperature = value.children.text

        time_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')

        sql = "INSERT INTO ant_miner (user, elapsed, hash, temperature, created_at) VALUES ('#{user}', '#{elapsed}', '#{ghsav}', '#{temperature}', '#{time_at}')"
        result = client.query(sql)
      end
    end
  end

  sleep(600)
end



