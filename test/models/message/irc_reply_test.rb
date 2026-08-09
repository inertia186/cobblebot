require 'test_helper'

class Message::IrcReplyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    Message::IrcReply.delete_all
  end

  def teardown
    Message::IrcReply.delete_all
  end

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

  def test_concurrent_creates_cull_after_both_transactions_commit
    9.times { |index| Message::IrcReply.create!(body: "baseline #{index}") }
    ready = Queue.new
    release = Queue.new

    threads = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Message::IrcReply.transaction do
            Message::IrcReply.create!(body: "concurrent #{index}")
            ready << true
            release.pop
          end
        end
      end
    end

    2.times { ready.pop }
    2.times { release << true }
    threads.each(&:value)

    assert_equal 10, Message::IrcReply.count
    assert_equal 2, Message::IrcReply.where("body LIKE 'concurrent %'").count
  end
end
