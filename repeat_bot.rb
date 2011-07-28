# -*- coding: utf-8 -*-
#
# Repeat_bot(Twitter) class library
# Author: ICHIKAWA, Yuji
# Copyright (C) 2011 ICHIKAWA, Yuji All rights reserved.

require 'twitter'
require 'monitor'

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

class Repeat_bot
  include MonitorMixin

  def initialize
    super()
    @schedule = []
    @client = Twitter::Client.new
    @thread = nil
  end

  def << task
    synchronize {@schedule << task}
    @thread = Thread.new {run} if @thread.nil? or not @thread.alive?
  end

  def push(*tasks)
    synchronize {@schedule.push(*tasks)}
    @thread = Thread.new {run} if @thread.nil? or not @thread.alive?
  end

  def run
    until synchronize {@schedule.empty?}
      task = synchronize do
        @schedule = @schedule.sort
        @schedule.delete_at(0)
      end
      t = task[0] - Time.now
      sleep(t) if t > 0
      tweet = '@' + task[1] + ' ' + task[2]
      @client.update(tweet[0,140])
    end
  end
end


