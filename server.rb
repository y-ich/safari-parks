# -*- coding: utf-8 -*-
#
# Bookmarklet連携CGIサーバー
#
require 'rubygems'
require 'sinatra'
require 'fast_stemmer' #for stem
require './dic-session'

get '/dic' do
  if params[:_callback]
    content_type 'text/javascript', :charset => 'utf-8'
  else
    content_type 'text/json', :charset => 'utf-8'
  end

  session = DicSession.new
  ids = session.search(params[:Word], 'EXACT')
  ids = session.search(params[:Word].stem, 'EXACT') if ids.empty?
  ids = session.search(params[:Word].stem, 'STARTWITH') if ids.empty?

  result = ids.inject('') { |m, e| m += session.retrieve(e) }
  session.close

  if params[:_callback] then
    params[:_callback] + '("' + result + '");'
  else
    '"' + result + '"'
  end
end
