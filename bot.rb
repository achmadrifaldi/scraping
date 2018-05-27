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

command = ''

def subscribe(client, chat_id)
  begin
    time_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    sql = "INSERT INTO users (chat_id, created_at) VALUES('#{chat_id}', '#{time_at}')"
    client.query(sql)
  rescue
    puts 'Duplicate Chat ID'
  end
end

def unsubscribe(client, chat_id)
  sql = "DELETE FROM users WHERE users.chat_id = '#{chat_id}'"
  client.query(sql)
end

def authorize(client, chat_id)
  sql = "SELECT * FROM users WHERE chat_id='#{chat_id}' LIMIT 1"
  user = client.query(sql).first

  !user.nil?
end

def help_text
  text = "You can control me by sending these commands:\n\n"
  text += "/start - Start a Bot\n"
  text += "/stop - Stop a Bot\n"
  text += "/top - Get latest data\n"
  text += "/watch - Start to get live data\n"
  text += "/endwatch - Stop to get live data\n"
  text += "/query - Manage data by query\n"
  text += "/reset - Reset a Bot\n"
  text += "/help - Get command info\n"
  text
end

def top(client)
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

  text
end

def watch(client, chat_id)
  sql = "UPDATE users SET watch = 1 WHERE users.chat_id = #{chat_id}"
  client.query(sql)
end

def endwatch(client, chat_id)
  sql = "UPDATE users SET watch = 0 WHERE users.chat_id = #{chat_id}"
  client.query(sql)
end

Telegram::Bot::Client.run(ENV['TELEGRAM_TOKEN']) do |bot|
  begin
    bot.listen do |message|
      if authorize(client, message.chat.id)
        case message.text
        when '/start'
          text = "I'm ready! Use /help to see the command."
          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/stop'
          unsubscribe(client, message.chat.id)
          text = "Bye bye! Have a nice day!"
          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/top'
          text = top(client)
          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/watch'
          watch(client, message.chat.id)
          text = "Enjoy the live data. Use /endwatch to stop watching the live data."
          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/endwatch'
          endwatch(client, message.chat.id)
          text = "You are no longer watching the data."
          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/query'
          command = '/query'
          query_text = "SELECT * FROM ant_miner WHERE temperature > 30  ORDER BY created_at DESC LIMIT 9"
          kb = [
            Telegram::Bot::Types::KeyboardButton.new(text: query_text)
          ]
          markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
          bot.api.send_message(chat_id: message.chat.id, text: "Please enter the query:", reply_markup: markup)
        when '/reset'
          command = ''
          text = "Let's start again!\n\n"
          text += help_text

          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/help'
          bot.api.send_message(chat_id: message.chat.id, text: help_text)
        else
          case command
          when '/query'
            kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
            bot.api.send_message(chat_id: message.chat.id, text: message.text)
            sql =  message.text
            results = client.query(sql) rescue []
            command = ''

            if results.count > 0
              string = ""
              list = ""

              results.each do |row|
                list = "USER" + " |  " + "TEMPERATURE" + "\n\n"
                string += row['user'] + "\t" + "-" + row['hash'] + "Gh/s" +  " " + "-" + row['temperature']+".C" + "\n" + "elpsed: \t" + row['elapsed'] + "\n"
              end

              text = "#{list} #{string}"
              bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: kb)
            else
              text = "No data available"
              bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: kb)
            end
          else
            text = "Use /help to see the command."
            bot.api.send_message(chat_id: message.chat.id, text: text)
          end
        end
      else
        case message.text
        when '/start'
          subscribe(client, message.chat.id)
          text = "Hello, #{message.from.first_name}!"
          bot.api.send_message(chat_id: message.chat.id, text: text)
        when '/help'
          bot.api.send_message(chat_id: message.chat.id, text: help_text)
        else
          text = "Use /start to start a bot. /help to see another command."
          bot.api.send_message(chat_id: message.chat.id, text: text)
        end
      end
    end
  rescue => e
    puts e.inspect
    retry
  end
end
