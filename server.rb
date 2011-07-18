# -*- coding: utf-8 -*-
#
# Bookmarklet連携CGIサーバー
#
require 'rubygems'
require 'sinatra'
require 'rexml/document'
require 'active_support' # for singularize
require 'fast_stemmer' #for stem
require './dic-session'

# 恒等関数がなさそうなので定義
def identity
  return self
end

get '/dic' do
  session = DicSession.new
  xml = nil
  result = ''
  if ['identity', 'singularize', 'stem'].find { |e| (xml = session.searchDic(params[:Word].send(e))) != nil} then
    REXML::XPath.each(xml, '//ItemID') do |e|
      result = result + session.retrieveDic(e.text)
    end
  end
  #if文の条件式がfalse(nil)になるのは、生でも単数形でもstemしても単語が見つからなかった時

  if params[:_callback]
    "Content-Type: text/javascript; charset=utf-8;\r\n\r\n" +
      params[:_callback] + '("' + result + '");'
  else
    "Content-Type: text/json; charset=utf-8;\r\n\r\n" + '"' + result + '"'
  end
end
