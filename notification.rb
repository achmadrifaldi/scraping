require 'rubygems'
require 'dotenv/load'
require 'mysql2'
require 'telegram/bot'

# Define Database Connection
client = Mysql2::Client.new(
  host: ENV['DB_HOST'],
  username: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD'],
  database: ENV['DB_NAME']
)

loop do
  user_sql = "SELECT * FROM users WHERE watch = 1 LIMIT 1"
  results = client.query(user_sql)

  if results.count > 0
    sql = "SELECT * FROM ant_miner WHERE temperature > 30  ORDER BY created_at DESC LIMIT 9"
    result = client.query(sql)
    text = ""

    if !result.first.nil?
      string = ""
      list = ""

      result.each do |row|
        list = "USER" + " |  " + "TEMPERATURE" + "\n\n"
        string += row['user'] + "\t" + "-" + row['hash'] + "Gh/s" +  " " + "-" + row['temperature']+".C" + "\n" + "elpsed: \t" + row['elapsed'] + "\n"
      end

      text = "#{list} #{string}"
    else
      text = "No data available"
    end

    results.each do |row|
      Telegram::Bot::Client.run(ENV['TELEGRAM_TOKEN']) do |bot|
        bot.api.send_message(chat_id: row['chat_id'], text: text)
      end
    end
  end

  sleep(1800)
end
