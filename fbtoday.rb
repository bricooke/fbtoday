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
  project_info = projects[te.project_id]

  if project_info.nil?
    project = FreshBooks::Project.get(te.project_id)
    project_info = {:project => project, :hours => 0.0}
    projects[te.project_id] = project_info
  end

  hours += te.hours
  project_info[:hours] += te.hours
  puts "#{te.hours}\t#{project.name}\t#{te.notes}"
end

puts "----"
projects.values.each do |project_info|
  puts "#{project_info[:hours]}\t#{project_info[:project].name}"
end

puts "#{hours}\tTotal"
