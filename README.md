# Scraping Bot Project

Scraping ant miner data and access the data from Telegram Bot

# Ruby Version
```
  ruby 2.4.0p0 (2016-12-24 revision 57164) [x86_64-linux]
```

# Ruby Gems List
  - gem install dotenv
  - gem install telegram-bot-ruby
  - gem install mysql2
  - gem install mechanize
  - gem install daemons

# How to Install
  1. Install all gem on the Ruby Gems List
  2. Import scraping.sql to mysql database
  3. Rename .env.example to .env
  4. Update environment variable in .env file

# Basic Usage

To start scraping the data, you can use this command from the console:

``` ruby
  $ ruby scraping_control.rb start
    (scraping.rb is now running in the background)
```

And to stop or restart the scraping process, use this command:

``` ruby
  $ ruby scraping_control.rb restart
      (...)
  $ ruby scraping_control.rb stop
```

Run this command to start receive data from telegram bot:

``` ruby
  ruby bot.rb
```
