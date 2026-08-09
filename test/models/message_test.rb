require 'test_helper'

class MessageTest < ActiveSupport::TestCase
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

  def test_worker_messages_allow_missing_associations
    message = Message::IrcReply.new(body: 'Server relay without a known player')

    assert message.valid?
    assert_nil message.author
    assert_nil message.recipient
    assert_nil message.parent
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

  def test_query_safely_loads_keywords_containing_sql_syntax
    payload = "x' OR 1=1 --"

    assert_empty Message.query(payload).load
  end

  def test_matching_stop_words_binds_quotes_and_treats_wildcards_literally
    quoted = messages(:nether_horses)
    percent = messages(:secure_oceans)
    unrelated = messages(:donation_from_resnullius)
    quoted.update_columns(body: "That can't be right")
    percent.update_columns(body: 'Progress is 100% complete')
    unrelated.update_columns(body: 'Progress is 1000 complete')
    Preference.stop_words = "can't 100%"

    assert_equal [quoted.id, percent.id].sort,
      Message.matching_stop_words.where(id: [quoted, percent, unrelated]).pluck(:id).sort
  end

  def test_matching_stop_words_returns_all_when_the_preference_is_blank
    Preference.stop_words = ''

    assert_equal Message.count, Message.matching_stop_words.count
  end
  
  def test_read
    message = Message.create(recipient_term: '@dinnerbone', body: 'Hello, Mr. Adams.')
    
    refute (read = Message.read).any?, "did not expect read, was: #{read.map(&:body)}"
    assert Message.read(false).any?, 'expect unread'
  end
end
