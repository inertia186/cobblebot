require 'resque/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task setup: :environment do
    Resque::Scheduler.dynamic = true
    Resque.schedule = YAML.safe_load_file(Rails.root.join('config/resque_schedule.yml'))
    Resque.before_fork = proc { ActiveRecord::Base.establish_connection }
  end
end
