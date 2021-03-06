require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  def setup
  end
  
  def test_recipient
    player = Player.last
    message = player.messages.build
    
    assert_equal player, message.recipient, 'expect player to be recipient'
  end

  def test_recipient_term
    player = Player.last
    message = Message.new(recipient_term: '@dinnerbone')
    
    assert_equal player, message.recipient, 'expect player to be recipient'
  end
  
  def test_query
    Rails.application.load_seed
    assert Message::Tip.query('minecraft').any?, 'expect minecraft tips'
    refute Message::Tip.query('lego').any?, 'did not expect lego tips'
    assert Message::Tip.query('minecraft', 'lego').any?, 'expect minecraft tips'
    refute Message::Tip.query("'\"").any?, 'did not expect results from SQL injection attempt'
    refute Message::Tip.query("\#{1/0}").any?, 'did not expect results from ruby injection attempt'
    assert Message::Tip.query.any?, 'expect all results'
  end
  
  def test_read
    message = Message.create(recipient_term: '@dinnerbone', body: 'Hello, Mr. Adams.')
    
    refute (read = Message.read).any?, "did not expect read, was: #{read.map(&:body)}"
    assert Message.read(false).any?, 'expect unread'
  end
end