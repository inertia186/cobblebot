class TopicsController < ApplicationController
  def index
    @topic = Message::Topic.last
    @topics = Message::Topic.order('messages.id DESC').limit(100).preload(:author)
    @past_topics = @topics.where.not(id: @topic)
  end
end
