abort 'Player authentication backfill requires production.' unless Rails.env.production?

time_zone = PlayerAuthenticationBackfill::DEFAULT_TIME_ZONE
today = Time.current.in_time_zone(time_zone).to_date
date = Date.parse(ENV.fetch('COBBLEBOT_BACKFILL_DATE', today.to_s))
abort 'Player authentication backfill is limited to the current local date.' unless date == today

expected_log = File.join(ServerProperties.path_to_server, 'logs', 'latest.log')
result = PlayerAuthenticationBackfill.call(
  log_path: expected_log, date: date, time_zone: time_zone
)

puts "authentication_events=#{result.events}"
puts "players_created=#{result.created}"
puts "players_updated=#{result.updated}"
