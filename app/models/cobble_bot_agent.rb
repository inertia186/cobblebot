class CobbleBotAgent < Mechanize
  def initialize
    super('cobblebot')

    @agent.user_agent = "CobbleBot version: #{COBBLEBOT_VERSION}"
    @agent.keep_alive = false
    @agent.open_timeout = 5
    @agent.read_timeout = 5
  end
end
