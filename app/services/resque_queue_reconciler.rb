class ResqueQueueReconciler
  Result = Struct.new(:status, :pending, keyword_init: true)

  STATUSES = {
    0 => :disabled,
    1 => :enqueued,
    2 => :already_present,
    3 => :reset,
    4 => :cleared
  }.freeze

  SCRIPT = <<~LUA.freeze
    local queue_key = KEYS[1]
    local queues_key = KEYS[2]
    local workers_key = KEYS[3]
    local target_class = ARGV[1]
    local desired_payload = ARGV[2]
    local queue_name = ARGV[3]
    local enabled = ARGV[4] == '1'
    local consider_running = ARGV[5] == '1'
    local entries = redis.call('LRANGE', queue_key, 0, -1)
    local matching = {}
    local matching_entry = nil
    local pending = 0

    for index, entry in ipairs(entries) do
      local decoded_ok, payload = pcall(cjson.decode, entry)
      local is_match = decoded_ok and type(payload) == 'table' and
        tostring(payload['class']) == target_class
      matching[index] = is_match
      if is_match then
        pending = pending + 1
        matching_entry = entry
      end
    end

    local function replace_entries(include_canonical)
      redis.call('DEL', queue_key)
      local inserted = false

      for index, entry in ipairs(entries) do
        if matching[index] then
          if include_canonical and not inserted then
            redis.call('RPUSH', queue_key, desired_payload)
            inserted = true
          end
        else
          redis.call('RPUSH', queue_key, entry)
        end
      end

      if include_canonical and not inserted then
        redis.call('RPUSH', queue_key, desired_payload)
      end

      if redis.call('LLEN', queue_key) == 0 then
        redis.call('SREM', queues_key, queue_name)
      else
        redis.call('SADD', queues_key, queue_name)
      end
    end

    local running = false
    if consider_running then
      local key_prefix = string.sub(workers_key, 1, string.len(workers_key) - string.len('workers'))
      for _, worker_id in ipairs(redis.call('SMEMBERS', workers_key)) do
        local worker_json = redis.call('GET', key_prefix .. 'worker:' .. worker_id)
        if worker_json then
          local decoded_ok, worker = pcall(cjson.decode, worker_json)
          local payload = decoded_ok and type(worker) == 'table' and worker['payload']
          if type(payload) == 'table' and tostring(payload['class']) == target_class then
            running = true
            break
          end
        end
      end
    end

    if not enabled then
      if pending == 0 then
        return {0, pending}
      end

      replace_entries(false)
      return {4, pending}
    end

    if running then
      if pending > 0 then
        replace_entries(false)
      end
      return {2, pending}
    end

    if pending == 0 then
      redis.call('SADD', queues_key, queue_name)
      redis.call('RPUSH', queue_key, desired_payload)
      return {1, pending}
    end

    if pending == 1 then
      redis.call('SADD', queues_key, queue_name)
      if matching_entry == desired_payload then
        return {2, pending}
      end

      replace_entries(true)
      return {3, pending}
    end

    replace_entries(true)
    return {3, pending}
  LUA

  def self.call(resque: Resque, worker_class:, enabled: true, args: [],
                consider_running: false)
    new(resque: resque).call(
      worker_class: worker_class,
      enabled: enabled,
      args: args,
      consider_running: consider_running
    )
  end

  def initialize(resque:)
    @resque = resque
  end

  def call(worker_class:, enabled: true, args: [], consider_running: false)
    queue = worker_class::QUEUE.to_s
    payload = resque.encode(
      'class' => worker_class.to_s,
      'args' => args
    )
    status_code, pending = resque.redis.eval(
      SCRIPT,
      keys: ["queue:#{queue}", 'queues', 'workers'],
      argv: [
        worker_class.to_s,
        payload,
        queue,
        enabled ? '1' : '0',
        consider_running ? '1' : '0'
      ]
    )

    Result.new(status: STATUSES.fetch(status_code), pending: pending)
  end

private
  attr_reader :resque
end
