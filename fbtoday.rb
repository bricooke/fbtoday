#!/usr/bin/env ruby
#
require 'freshbooks.rb'

FreshBooks::Base.establish_connection('roobasoftllc.freshbooks.com', ENV['FBAPI_TOKEN'])

date = ARGV[0]
if date
  date = Date.parse(date)
else
  date = Date.today
end

hours = 0.0

FreshBooks::TimeEntry.list(:date_from => date, :date_to => date).each do |te|
  project = FreshBooks::Project.get(te.project_id)
  hours += te.hours
  puts "#{te.hours}\t#{project.name}\t#{te.notes}"
end

puts "----"
puts "#{hours}"
