# -*- coding: utf-8 -*-
#
# JSONP Japanese-English dictionary server with twitter bot cooperation
# Author: ICHIKAWA, Yuji
# Usage:
#   GET parameters - Word, _callback, twitter_id
# Copyright (C) 2011 ICHIKAWA, Yuji All rights reserved.

require 'sinatra'
require 'fast_stemmer' #for stem
require 'pg'
require 'active_record'
require 'logger'
require 'delayed_job'
require 'twitter'

configure do
  config = YAML::load(File.open('config/database.yml'))
  environment = Sinatra::Application.environment.to_s
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.establish_connection(config[environment])
  Delayed::Worker.guess_backend
  Delayed::Worker.max_attempts = 1
end



# 「自然に学習」 on nextliteracy
CONSUMER_KEY = 'uJc6bLJMjoA2dJ1xnkhvyw'
CONSUMER_SECRET = 'Z10pLyTGuZVbYEbr2MHqkyUIQo3wkQDDROjMYOWbo'
# repeat_botの認証
ACCESS_TOKEN = '343043759-NtkQE7odf9T26eTB6vaa07keyaSSMaU8YhuvUBd4'
ACCESS_TOKEN_SECRET = '22qnX1llOsuzwb2gogcOQ0dWfO1lTak84JAH4u7CkE'

Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = ACCESS_TOKEN
  config.oauth_token_secret = ACCESS_TOKEN_SECRET
end
repeat_bot = Twitter::Client.new

DIC_FILE = 'PrepTutorEJDIC/PrepTutorEJDIC.UTF-8.txt'

# returns search result.
# The format of returned value is ["word\nmeaning", "word\nmeaning", ...].
def search(word, condition = 'exact')
  reg = Regexp.new(condition == 'beginwith' ? "^#{word}" : "^#{word}\\t", true)
  # dictionary line format is "word\tmeaning\n"
    
  result = []
  File.open(DIC_FILE) do |f|
    until f.eof?
      line = f.gets
      result << line.chomp.sub(/\t/, '\n') if reg =~ line
    end
  end
  return result
end

get '/dic' do
  result = search(params[:Word])
  if result.empty?
    stem = params[:Word].stem
    result = search(stem)
    if result.empty?
      result = search(stem, 'beginwith')
    end
  end
  result = result.join('\n')

  if params[:twitter_id] and not result.empty?
    INTERVALS = [0, 1, 24, 24*7, 24*30]
    tweet = '@' + params[:twitter_id] + ' ' + result
    INTERVALS.each do |interval|
      repeat_bot.delay(:run_at => interval.hours.from_now).update(tweet[0,140])
    end
  end

  if params[:_callback]
    content_type('text/javascript', :charset => 'utf-8')
    params[:_callback] + '("' + result + '");'
  else
    content_type('text/json', :charset => 'utf-8')
    '"' + result + '"'
  end
end

