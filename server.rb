# -*- coding: utf-8 -*-
#
# JSONP Japanese-English dictionary server with twitter bot cooperation
# Author: ICHIKAWA, Yuji
# Usage:
#   GET parameters - Word, _callback, twitter_id
# Copyright (C) 2011 ICHIKAWA, Yuji All rights reserved.

require 'sinatra'
require 'fast_stemmer' #for stem
require './repeat_bot'

DIC_FILE = 'PrepTutorEJDIC/PrepTutorEJDIC.UTF-8.txt'
repeat_bot = Repeat_bot.new

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
    t = Time.now
    [60*60, 60*60*24, 60*60*24*7, 60*60*24*30].each do |e|
      repeat_bot << [t + e, params[:twitter_id], result]
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

