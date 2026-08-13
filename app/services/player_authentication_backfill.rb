require 'pathname'

class PlayerAuthenticationBackfill
  MAX_LOG_BYTES = 64 * 1024 * 1024
  DEFAULT_TIME_ZONE = 'America/Los_Angeles'
  Result = Struct.new(:events, :created, :updated, keyword_init: true)

  def self.call(log_path:, date:, time_zone: DEFAULT_TIME_ZONE)
    new(log_path: log_path, date: date, time_zone: time_zone).call
  end

  def initialize(log_path:, date:, time_zone:)
    @log_path = Pathname(log_path)
    @date = Date.parse(date.to_s)
    @time_zone = Time.find_zone!(time_zone)
  end

  def call
    validate_log!
    events = authentication_events
    created = 0
    updated = 0

    Player.transaction do
      events.each_value do |event|
        if Player.find_by_uuid(event.fetch(:uuid))
          updated += 1
        else
          created += 1
        end

        player = ServerCommand.player_authenticated(
          event.fetch(:nick), event.fetch(:uuid), at: event.fetch(:at)
        )
        raise ActiveRecord::RecordInvalid, player unless player&.persisted?
      end
    end

    Result.new(events: events.length, created: created, updated: updated)
  end

private
  def validate_log!
    stat = @log_path.lstat
    raise ArgumentError, 'authentication log must not be a symlink' if stat.symlink?
    raise ArgumentError, 'authentication log must be a regular file' unless stat.file?
    raise ArgumentError, 'authentication log exceeds the size limit' if stat.size > MAX_LOG_BYTES
  end

  def authentication_events
    events = {}

    @log_path.each_line do |line|
      match = line.match(ServerCallback::REGEX_PLAYER_AUTHENTICATED)
      next unless match

      hour, minute, second = line[1, 8].split(':').map(&:to_i)
      at = @time_zone.local(@date.year, @date.month, @date.day, hour, minute, second)
      events[match[2]] = {nick: match[1], uuid: match[2], at: at}
    end

    events
  end
end
