class ResqueConfiguration
  CONFIG_PATH = Rails.root.join('config/resque.yml')
  DEFAULT_NAMESPACE = 'resque'

  attr_reader :namespace, :redis_url

  def self.load(environment:, env: ENV, path: CONFIG_PATH)
    settings = YAML.safe_load(File.read(path))
    configured_url = settings.fetch(environment.to_s)

    new(
      redis_url: env['COBBLEBOT_REDIS_URL'].to_s.empty? ? configured_url : env['COBBLEBOT_REDIS_URL'],
      namespace: env['COBBLEBOT_RESQUE_NAMESPACE'].to_s.empty? ? DEFAULT_NAMESPACE : env['COBBLEBOT_RESQUE_NAMESPACE']
    )
  end

  def initialize(redis_url:, namespace: DEFAULT_NAMESPACE)
    @redis_url = redis_url
    @namespace = namespace
  end

  def apply(resque: Resque, redis: Redis, namespace_class: Redis::Namespace)
    client = redis.connect(url: redis_url, thread_safe: true)
    namespaced_client = namespace_class.new(namespace, redis: client)
    resque.redis = namespaced_client
    namespaced_client
  end
end
