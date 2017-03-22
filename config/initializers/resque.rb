require 'resque-scheduler'
require 'resque/scheduler/server'

Resque.logger = Logger.new(Rails.root.join('log', "#{Rails.env}_resque.log"))

Resque.schedule = YAML.load_file(File.join(Rails.root, 'config/resque_scheduler.yml'))