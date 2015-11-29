require 'slack'

# https://api.slack.com
class SlackBot < Slack::Client
  MAX_BACKOFF = 51.2
  INITIAL_BACKOFF = 0.1

  def initialize(options = {})
    @backoff = INITIAL_BACKOFF
    @config ||= Slack.configure do |config|
      config.token = SlackBot.api_key
    end

    super
  end

  def self.instance=(instance)
    @@instance = instance
  end

  def self.instance
    if @api_key != Preference.slack_api_key
      @@instance = SlackBot.new
    end

    @@instance
  end

  def self.api_key
    @api_key = Preference.slack_api_key
  end

  def self.configured?
    @config.present?
  end

  def group
    @group ||= Preference.slack_group
  end

  def say(text)
    sleep @backoff

    begin
      chat_postMessage(channel: group, as_user: true, text: text)
    rescue => e
      Rails.logger.error e.inspect
      @backoff = @backoff * 2

      if @backoff > MAX_BACKOFF
        SlackBot.instance = SlackBot.new
      end

      false
    end
  end

  def topic(text)
    groups_setTopic(channel: group, topic: text)
  end

  SlackBot.instance = SlackBot.new
end

module Slack
  extend Configuration

  def self.client(options={})
    SlackBot.new(options)
  end

  # Delegate to Slack::Client
  def self.method_missing(method, *args, &block)
    return super unless client.respond_to?(method)
    client.send(method, *args, &block)
  end

  # Delegate to Slack::Client
  def self.respond_to?(method, include_all=false)
    return client.respond_to?(method, include_all) || super
  end
end
