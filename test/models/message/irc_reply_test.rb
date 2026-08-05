require 'test_helper'

class Message::IrcReplyTest < ActiveSupport::TestCase
  def test_defaults_the_recipient_term
    assert_equal '@a', Message::IrcReply.new.recipient_term
  end

  def test_cull_retains_the_ten_newest_replies
    created_ids = 12.times.map do |index|
      Message::IrcReply.create!(body: "IRC reply #{index}").id
    end

    assert_equal created_ids.last(10), Message::IrcReply.order(:id).pluck(:id)
  end

  def test_cull_is_idempotent
    3.times { |index| Message::IrcReply.create!(body: "IRC reply #{index}") }

    assert_no_difference -> { Message::IrcReply.count } do
      Message::IrcReply.cull
      Message::IrcReply.cull
    end
  end
end
