require 'test_helper'

class Api::V1::MessagesControllerTest < ActionController::TestCase
  def setup
    @attributes = %w(body recipient_term read_at created_at author_nick recipient_nick)
  end

  def test_routings
    assert_routing 'api/messages', controller: 'api/v1/messages', action: 'index', format: 'json'
    assert_routing 'api/messages/42', controller: 'api/v1/messages', action: 'show', id: '42', format: 'json'
  end

  def test_index
    get :index, format: :json
    assert_response 200

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_index_with_limit
    limit = 1
    get :index, format: :json, limit: limit
    assert_response 200

    assert_equal limit, response_json.size

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_index_by_author
    refute_nil message = Message.first
    get :index, format: :json, author_id: message.author
    assert_response 200

    response_json.each do |json|
      refute_nil message = Message.find_by_uuid(json['uuid'])

      @attributes.each do |attr|
        case attr
        when 'author_nick'
          assert_equal message.author.nick, json[attr]
        when 'recipient_nick'
          assert_equal message.recipient.nick, json[attr]
        else
          assert_equal message.send(attr), json[attr]
        end
      end
    end

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_index_by_any_recipient_nick
    dinnerbone = Player.find_by_nick('Dinnerbone')
    get :index, format: :json, any_recipient_nick: dinnerbone.nick
    assert_response 200

    response_json.each do |json|
      refute_nil message = Message.find_by_uuid(json['uuid'])

      @attributes.each do |attr|
        case attr
        when 'author_nick'
          assert_equal message.author.nick, json[attr]
        when 'recipient_nick'
          assert_equal message.recipient.nick, json[attr]
        else
          assert_equal message.send(attr), json[attr]
        end
      end
    end

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_show
    dinnerbone = Player.find_by_nick('Dinnerbone')
    message = dinnerbone.messages.last
    # TODO use request_token
    #request_token @access_token.token
    get :show, id: message.id, format: :json
    assert_response 200
    @attributes.each do |attr|
      case attr
      when 'author_nick'
        assert_equal message.author.nick, response_json[attr]
      when 'recipient_nick'
        assert_equal message.recipient.nick, response_json[attr]
      else
        assert_equal message.send(attr), response_json[attr]
      end
    end

    assert_template :show
    assert_template partial: "api/v1/messages/_minimal_message"
  end
end
