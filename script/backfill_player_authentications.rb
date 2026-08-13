abort 'Player authentication backfill requires production.' unless Rails.env.production?

date = Date.parse(ENV.fetch('COBBLEBOT_BACKFILL_DATE', Time.zone.today.to_s))
abort 'Player authentication backfill is limited to the current local date.' unless date == Time.zone.today

expected_log = File.join(ServerProperties.path_to_server, 'logs', 'latest.log')
result = PlayerAuthenticationBackfill.call(log_path: expected_log, date: date)

puts "authentication_events=#{result.events}"
puts "players_created=#{result.created}"
puts "players_updated=#{result.updated}"
