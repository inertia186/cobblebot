RAILS_ROOT = File.dirname(File.dirname(__FILE__))

God.watch do |w|
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 10.seconds
      c.running = false
    end
  end

  w.dir = RAILS_ROOT
  w.name = "minecraft_server_log_monitor"
  w.group = "cobblebot"
  w.interval = 300.seconds
  w.start = "cd #{RAILS_ROOT} && BACKGROUND=yes RAILS_ENV='development' rake resque:scheduler && TERM_CHILD=1 RAILS_ENV='development' QUEUE='minecraft_server_log_monitor' rake resque:work"
  w.start_grace = 20.seconds
  w.restart_grace = 20.seconds
  w.pid_file = "#{RAILS_ROOT}/log/cobblebot-resque.pid"

  w.behavior(:clean_pid_file)
end
