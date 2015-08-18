class TopicsController < ApplicationController
  def index
    @topic = Message::Topic.last
    @past_topics = Message::Topic.where.not(id: @topic).limit(100)
  end
end
