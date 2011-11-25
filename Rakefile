require 'delayed/tasks'
require './server.rb'

task :ready => ['public/dic/bml.html', 'views/dic/index.erb']

task :environment

namespace :db do
  desc 'Migrate the database'
  task :migrate => :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate('db/migrate')
  end
end

file 'views/dic/index.erb' => ['views/dic/index.erb.erb', 'bookmarklets/dic.min.js', 'bookmarklets/dic_ipad.min.js', 'bookmarklets/dic_iphone.min.js'] do |t|
  sh "erb #{t.prerequisites[0]} > #{t.name}"
end

file 'public/dic/bml.html' => ['public/dic/bml.erb', 'bookmarklets/pronounce.min.js'] do |t|
  sh "erb #{t.prerequisites[0]} > #{t.name}"
end

rule(/\.min.js$/ => [proc {|file_name| file_name.sub(/\.min.js$/, '.js')}]) do |t|
  sh "uglifyjs -o #{t.name} #{t.prerequisites[0]}"
end
