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

staff = nil
tasks = nil

FreshBooks::TimeEntry.list(:date_from => date, :date_to => to_date).each do |te|
  project_info = projects[te.project_id]

  if project_info.nil?
    project = FreshBooks::Project.get(te.project_id)
    project_info = {:project => project, :hours => 0.0, :moneys => 0.0}
    projects[te.project_id] = project_info
  end

  # check for a project filter.
  if ENV["PROJECT"] && ENV["PROJECT"] != project_info[:project].name
    next
  end

  hours += te.hours
  project_info[:hours] += te.hours

  if tasks == nil
    tasks = FreshBooks::Task.list
  end

  current_task = nil
  tasks.each do |task|
    if task.task_id == te.task_id
      current_task = task
    end
  end

  if current_task.billable
    if project_info[:project].bill_method == "project-rate"
      project_info[:moneys] += te.hours * project_info[:project].rate
    elsif project_info[:project].bill_method == "task-rate"
      project_info[:project].tasks.each do |task|
        if task.task_id == te.task_id
          project_info[:moneys] += task.rate * te.hours
        end
      end
    elsif project_info[:project].bill_method == "staff-rate"
      if staff == nil
        # go fish!
        staff = FreshBooks::Staff.list

        # [{"staff_id":1,"number_of_logins":142,"username":"bricooke","first_name":"Brian","last_name":"Cooke","email":"brian@roobasoft.com","business_phone":"208.914.1785","mobile_phone":"","street1":"","street2":"","city":"","state":"","country":"","code":"","rate":120.0,"last_login":"2012-07-12T20:15:28+00:00","signup_date":"2012-02-05T11:41:15+00:00"}]
        staff.each do |staff_entry|
          if staff_entry.staff_id == te.staff_id
            project_info[:moneys] += staff_entry.rate * te.hours
          end
        end
      end
    end
  end

  STDOUT.write "#{"%04.2f" % te.hours}\t#{project_info[:project].name}\t"

  if date != to_date
    # different days? show which is where
    STDOUT.write "#{te.date}\t"
  end

  puts "#{te.notes}" 
end

puts "----"
total_moneys = 0.0

projects.values.each do |project_info|
  next unless project_info[:hours] > 0.0

  if project_info[:project].bill_method == "flat-rate"
    project_info[:moneys] = -1
  end

  moneys_to_show = ((project_info[:moneys] * 100).to_i) / 100.0

  if moneys_to_show < 0
    moneys_to_show = "N/A"
  else
    total_moneys += moneys_to_show
    moneys_to_show = "$#{moneys_to_show}"
  end

  puts "#{"%04.2f" % project_info[:hours]}\t#{moneys_to_show}\t#{project_info[:project].name}"
end

puts "#{"%04.2f" % hours}\t$#{total_moneys}\tTotal"
