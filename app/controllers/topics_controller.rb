class TopicsController < ApplicationController
  def index
    @topic = Message::Topic.latest_topics.limit(1).last
    @topics = Message::Topic.latest_topics.limit(100).preload(:author)
    @past_topics = @topics.where.not(id: @topic)
  end
end
