require 'slack'

# https://github.com/inertia186/beeline-rb
class BeechatBot < Beeline::Bot
  MAX_BACKOFF = 51.2
  INITIAL_BACKOFF = 0.1

  def initialize(options = {})
    @backoff = INITIAL_BACKOFF

    super
  end

  def self.instance=(instance)
    @@instance = instance
  end

  def self.instance
    @@instance ||= BeechatBot.new
  end

  def group
    @group ||= Preference.beechat_group
  end

  def say(text)
    sleep @backoff

    begin
      chat_message(group, nil, text)
    rescue => e
      Rails.logger.error e.inspect
      @backoff = @backoff * 2

      if @backoff > MAX_BACKOFF
        BeechatBot.instance = BeechatBot.new
      end

      false
    end
  end

  def topic(text)
    # TODO (not yet supported)
  end

  BeechatBot.instance = BeechatBot.new
end
