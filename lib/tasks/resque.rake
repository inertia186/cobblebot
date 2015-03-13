require 'resque/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task setup: :environment do
    Resque::Scheduler.dynamic = true
    Resque.schedule = YAML.load_file(Rails.root + 'config' + 'resque_schedule.yml')
    Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
  end
  
  namespace :pool do
    task setup: :environment do
      # close any sockets or files in pool manager
      ActiveRecord::Base.connection.disconnect!
      # and re-open them in the resque worker parent
      Resque::Pool.after_prefork do |job|
        ActiveRecord::Base.establish_connection
        Resque.redis.client.reconnect
      end
    end
  end
  #task scheduler_setup: :setup_schedule
end
