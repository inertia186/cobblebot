require 'concurrent'

class IrcCommandDispatcher
  MAX_THREADS = 2
  MAX_QUEUE = 8
  RATE_WINDOW = 10.0
  PER_SENDER_LIMIT = 3
  GLOBAL_LIMIT = 12
  SHUTDOWN_TIMEOUT = 5

  def initialize(
    executor: nil,
    logger: Rails.logger,
    clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
    rails_executor: Rails.application.executor,
    rate_window: RATE_WINDOW,
    per_sender_limit: PER_SENDER_LIMIT,
    global_limit: GLOBAL_LIMIT
  )
    @executor = executor || Concurrent::ThreadPoolExecutor.new(
      min_threads: MAX_THREADS,
      max_threads: MAX_THREADS,
      max_queue: MAX_QUEUE,
      fallback_policy: :discard,
      name: 'cobblebot-irc-command'
    )
    @logger = logger
    @clock = clock
    @rails_executor = rails_executor
    @rate_window = rate_window
    @per_sender_limit = per_sender_limit
    @global_limit = global_limit
    @mutex = Mutex.new
    @sender_events = {}
    @global_events = []
    @stopped = false
  end

  def submit(sender_key, &task)
    raise ArgumentError, 'no command task given' unless task

    admission = admit(sender_key.to_s)
    return admission unless admission == :accepted

    posted = @executor.post { execute(task) }
    return :accepted if posted

    stopped? ? :stopped : :queue_full
  end

  def shutdown(timeout: SHUTDOWN_TIMEOUT)
    should_shutdown = @mutex.synchronize do
      next false if @stopped

      @stopped = true
    end
    return true unless should_shutdown

    @executor.shutdown
    @executor.kill unless @executor.wait_for_termination(timeout)
    true
  end

private
  def admit(sender_key)
    @mutex.synchronize do
      return :stopped if @stopped

      now = @clock.call
      prune_events(now)
      sender_events = (@sender_events[sender_key] ||= [])

      return :sender_rate_limited if sender_events.length >= @per_sender_limit
      return :global_rate_limited if @global_events.length >= @global_limit

      sender_events << now
      @global_events << now
      :accepted
    end
  end

  def prune_events(now)
    cutoff = now - @rate_window
    @global_events.shift while @global_events.first && @global_events.first <= cutoff
    @sender_events.delete_if do |_sender_key, events|
      events.shift while events.first && events.first <= cutoff
      events.empty?
    end
  end

  def execute(task)
    @rails_executor.wrap { task.call }
  rescue StandardError => e
    @logger.error "IRC command handler failed: #{e.class}: #{e.message}"
  end

  def stopped?
    @mutex.synchronize { @stopped }
  end
end
