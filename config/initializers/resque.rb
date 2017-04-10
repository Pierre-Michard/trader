#require 'resque-scheduler'
#require 'resque/scheduler/server'
#require 'active_scheduler'

Resque.logger = Logger.new(Rails.root.join('log', "#{Rails.env}_resque.log"))

#yaml_schedule    = YAML.load_file(File.join(Rails.root, 'config/resque_scheduler.yml')) || {}
#wrapped_schedule = ActiveScheduler::ResqueWrapper.wrap yaml_schedule
#Resque.schedule  = wrapped_schedule