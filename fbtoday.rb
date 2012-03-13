#!/usr/bin/env ruby
require 'freshbooks.rb'

def parsed_date_or_today(potential_date)
  date = potential_date
  if date
    date = Date.parse(date)
  else
    date = Date.today
  end
  date
end

# Main
FreshBooks::Base.establish_connection('roobasoftllc.freshbooks.com', ENV['FBAPI_TOKEN'])

date = parsed_date_or_today(ARGV[0])
to_date = parsed_date_or_today(ARGV[1])

hours = 0.0
projects = {}

FreshBooks::TimeEntry.list(:date_from => date, :date_to => to_date).each do |te|
  project_info = projects[te.project_id]

  if project_info.nil?
    project = FreshBooks::Project.get(te.project_id)
    project_info = {:project => project, :hours => 0.0}
    projects[te.project_id] = project_info
  end

  # check for a project filter.
  if ENV["PROJECT"] && ENV["PROJECT"] != project_info[:project].name
    next
  end

  hours += te.hours
  project_info[:hours] += te.hours

  STDOUT.write "#{"%04.2f" % te.hours}\t#{project_info[:project].name}\t"

  if date != to_date
    # different days? show which is where
    STDOUT.write "#{te.date}\t"
  end

  puts "#{te.notes}" 
end

puts "----"
projects.values.each do |project_info|
  next unless project_info[:hours] > 0.0
  puts "#{"%04.2f" % project_info[:hours]}\t#{project_info[:project].name}"
end

puts "#{"%04.2f" % hours}\tTotal"
