require 'slack'

# https://api.slack.com
class SlackBot < Slack::Client
  def initialize(options = {})
    @config ||= Slack.configure do |config|
      config.token = SlackBot.api_key
    end

    super
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
    chat_postMessage(channel: group, as_user: true, text: text)
  end

  def topic(text)
    groups_setTopic(channel: group, topic: text)
  end
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
