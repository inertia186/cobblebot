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
    stat = validate_log!
    events = authentication_events(stat)
    created = 0
    updated = 0

    Player.transaction do
      events.each_value do |event|
        existing = Player.exists?(uuid: event.fetch(:uuid))
        player = ServerCommand.player_authenticated(
          event.fetch(:nick), event.fetch(:uuid), at: event.fetch(:at)
        )
        raise ActiveRecord::RecordInvalid, player unless player&.persisted?
        existing ? updated += 1 : created += 1
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
    unless stat.mtime.in_time_zone(@time_zone).to_date == @date && stat.mtime <= Time.current
      raise ArgumentError, 'authentication log date is stale or in the future'
    end
    stat
  end

  def authentication_events(stat)
    events = {}
    previous_at = nil
    contents = @log_path.binread(MAX_LOG_BYTES + 1)
    after = @log_path.lstat
    unless [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime] ==
           [after.dev, after.ino, after.size, after.mtime, after.ctime] && contents.bytesize == stat.size
      raise ArgumentError, 'authentication log changed while reading'
    end

    contents.each_line do |line|
      clock = line.match(/\A\[(\d{2}):(\d{2}):(\d{2})\]/)
      next unless clock

      hour, minute, second = clock.captures.map(&:to_i)
      unless hour < 24 && minute < 60 && second < 60
        raise ArgumentError, 'authentication log has an invalid clock'
      end
      wall_time = Time.utc(@date.year, @date.month, @date.day, hour, minute, second)
      unless @time_zone.tzinfo.periods_for_local(wall_time).length == 1
        raise ArgumentError, 'authentication log has an ambiguous local time'
      end
      at = @time_zone.local(@date.year, @date.month, @date.day, hour, minute, second)
      if at > stat.mtime || (previous_at && at < previous_at)
        raise ArgumentError, 'authentication log has ambiguous or future entries'
      end
      previous_at = at

      match = line.match(ServerCallback::REGEX_PLAYER_AUTHENTICATED)
      next unless match

      events[match[2]] = {nick: match[1], uuid: match[2], at: at}
    end

    events
  end
end
