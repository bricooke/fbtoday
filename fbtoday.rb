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
projects = {}

FreshBooks::TimeEntry.list(:date_from => date, :date_to => date).each do |te|
  project = projects[te.project_id]

  if project.nil?
    project = FreshBooks::Project.get(te.project_id)
    projects[te.project_id] = project
  end

  hours += te.hours
  puts "#{te.hours}\t#{project.name}\t#{te.notes}"
end

puts "----"
puts "#{hours}"
