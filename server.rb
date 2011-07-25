# -*- coding: utf-8 -*-
#
# Bookmarklet連携CGIサーバー
#
require 'rubygems'
require 'sinatra'
require 'fast_stemmer' #for stem
# require './dic-session' # ローカル辞書にしてイースト辞書webサービスは使わないようにした。

DIC_FILE = 'PrepTutorEJDIC/PrepTutorEJDIC.UTF-8.txt'

def search(word, condition = 'exact')
  if condition == 'beginwith' then
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

  if params[:_callback]
    content_type 'text/javascript', :charset => 'utf-8'
  else
    content_type 'text/json', :charset => 'utf-8'
  end

  result = search(word)
  if result.empty? then
    stem = word.stem
    result = search(stem)
    if result.empty? then
      result = search(stem, 'beginwith')
    end
  end

  result = result.join('\n')
  if params[:_callback] then
    params[:_callback] + '("' + result + '");'
  else
    '"' + result + '"'
  end
end
