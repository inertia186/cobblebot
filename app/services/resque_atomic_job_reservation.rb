class ResqueAtomicJobReservation
  SCRIPT = <<~LUA.freeze
    local payload_json = redis.call('LINDEX', KEYS[1], 0)
    if not payload_json then
      return nil
    end

    local payload = cjson.decode(payload_json)
    redis.call('LPOP', KEYS[1])
    redis.call('SET', KEYS[2], cjson.encode({
      queue = ARGV[1],
      run_at = ARGV[2],
      payload = payload
    }))
    return payload_json
  LUA

  def self.call(resque: Resque, worker:, queue:)
    payload_json = resque.redis.eval(
      SCRIPT,
      keys: ["queue:#{queue}", "worker:#{worker}"],
      argv: [queue, Time.now.utc.iso8601]
    )
    return unless payload_json

    Resque::Job.new(queue, resque.decode(payload_json))
  end
end
