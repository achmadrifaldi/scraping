require 'rubygems'
require 'dotenv/load'
require 'mysql2'
require 'mechanize'
require 'telegram/bot'

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

  sql = "SELECT * FROM users WHERE watch = 1 LIMIT 1"
  results = client.query(sql)

  if results.count > 0
    list = "USER" + " |  " + "TEMPERATURE" + "\n\n"
    string = ""
  end

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

        if results.count > 0
          string += user + "\t" + "-" + ghsav + "Gh/s" +  " " + "-" + temperature +".C" + "\n" + "elpsed: \t" + elapsed + "\n"
        end
      end
    end
  end

  if results.count > 0
    text = "#{list} #{string}"

    results.each do |row|
      Telegram::Bot::Client.run(ENV['TELEGRAM_TOKEN']) do |bot|
        bot.api.send_message(chat_id: row['chat_id'], text: text)
      end
    end
  end

  sleep(5)
end



