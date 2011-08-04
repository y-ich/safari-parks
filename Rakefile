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

file "bookmarklets/dic.min.js" => "bookmarklets/dic.js" do |t|
  File.open(t.prerequisites[0], 'r') do |orig|
    File.open(t.name, 'w') do |min|
      min.puts JSMin.minify(orig)
    end
  end
end