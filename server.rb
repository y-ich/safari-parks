# -*- coding: utf-8 -*-
#
# Bookmarklet連携CGIサーバー
#
require 'sinatra'
require 'fast_stemmer' #for stem
# require './dic-session' # ローカル辞書にしてイースト辞書webサービスは使わないようにした。
require './repeat_bot'

DIC_FILE = 'PrepTutorEJDIC/PrepTutorEJDIC.UTF-8.txt'
repeat_bot = Repeat_bot.new

def search(word, condition = 'exact')
  if condition == 'beginwith'
    reg = Regexp.new("^#{word}", true)
  else
    reg = Regexp.new("^#{word}\\t", true)
  end
    
  result = []
  File.open(DIC_FILE) { |f|
    until f.eof?
      line = f.gets
      line.chomp!
      result.insert(-1, line.sub(/\t/, '\n')) if reg =~ line
      # ここで単語の後のtabを改行に換える整形もしておく。
    end
  }

  return result
end

get '/dic' do
  word = params[:Word]

  result = search(word)
  if result.empty?
    stem = word.stem
    result = search(stem)
    if result.empty?
      result = search(stem, 'beginwith')
    end
  end

  result = result.join('\n')

  if params[:twitter_id]
    t = Time.now
    repeat_bot << [t + 60*60, params[:twitter_id], result]
    repeat_bot << [t + 60*60*24, params[:twitter_id], result]
    repeat_bot << [t + 60*60*24*7, params[:twitter_id], result]
    repeat_bot << [t + 60*60*24*30, params[:twitter_id], result]
  end

  if params[:_callback]
    content_type('text/javascript', :charset => 'utf-8')
    params[:_callback] + '("' + result + '");'
  else
    content_type('text/json', :charset => 'utf-8')
    '"' + result + '"'
  end
end

