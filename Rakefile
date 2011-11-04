require 'delayed/tasks'
require 'jsmin'
require './server.rb'

task :environment

namespace :db do
  desc "Migrate the database"
  task :migrate => :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

rule(/\.min.js$/ => [proc {|file_name| file_name.sub(/\.min.js$/, '.js')}]) do |t|
  File.open(t.prerequisites[0], 'r') do |orig|
    File.open(t.name, 'w') do |min|
      min.puts JSMin.minify(orig).gsub(/[\r\n\f]/, '')
    end
  end
end
