class TopicsController < ApplicationController
  def index
    @topic = Message::Topic.deleted(false).last
    @topics = Message::Topic.deleted(false).order('messages.id DESC').limit(100).preload(:author)
    @past_topics = @topics.where.not(id: @topic)
  end
end
