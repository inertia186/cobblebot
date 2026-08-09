require 'test_helper'

class Api::V1::MessagesControllerTest < ActionController::TestCase
  def setup
    @attributes = %w(body recipient_term read_at created_at author_nick recipient_nick)
    request_token Preference.web_admin_password
  end

  def test_routings
    assert_routing 'api/messages', controller: 'api/v1/messages', action: 'index', format: 'json'
    assert_routing 'api/messages/42', controller: 'api/v1/messages', action: 'show', id: '42', format: 'json'
  end

  def test_index_rejects_a_missing_token
    @request.headers['Authorization'] = nil

    get :index, params: {format: :json}

    assert_response :unauthorized
  end

  def test_index_rejects_an_invalid_token
    request_token 'invalid-token'

    get :index, params: {format: :json}

    assert_response :unauthorized
  end

  def test_index
    get :index, params: { format: :json }
    assert_response 200

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_index_with_limit
    limit = 1
    get :index, params: { format: :json, limit: limit }
    assert_response 200

    assert_equal limit, response_json.size

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_index_by_author
    target = Message.where(type: nil).where.not(author_id: nil).first
    refute_nil target
    other_author = Player.where.not(id: target.author_id).first
    nonmatching = Message.create!(
      body: 'different author control',
      author: other_author,
      recipient: target.recipient,
      recipient_term: target.recipient_term
    )
    get :index, params: { format: :json, author_id: target.author_id }
    assert_response 200

    refute_empty response_json
    refute_includes response_json.map { |json| json['uuid'] }, nonmatching.uuid
    response_json.each do |json|
      message = Message.find_by_uuid(json['uuid'])
      refute_nil message
      assert_equal target.author_id, message.author_id

      @attributes.each do |attr|
        case attr
        when 'author_nick'
          assert_equal message.author.nick, json[attr]
        when 'recipient_nick'
          assert_equal message.recipient.nick, json[attr]
        else
          assert_serialized_value message.send(attr).as_json, json[attr]
        end
      end
    end

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_index_by_any_recipient_nick
    dinnerbone = Player.find_by_nick('Dinnerbone')
    other_recipient = Player.where.not(id: dinnerbone.id).first
    nonmatching = Message.create!(
      body: 'different recipient control',
      author: dinnerbone,
      recipient: other_recipient,
      recipient_term: "@#{other_recipient.nick}"
    )
    get :index, params: { format: :json, any_recipient_nick: dinnerbone.nick }
    assert_response 200

    refute_empty response_json
    refute_includes response_json.map { |json| json['uuid'] }, nonmatching.uuid
    response_json.each do |json|
      message = Message.find_by_uuid(json['uuid'])
      refute_nil message
      assert_equal dinnerbone.id, message.recipient_id
      assert_equal 'Player', message.recipient_type

      @attributes.each do |attr|
        case attr
        when 'author_nick'
          assert_equal message.author.nick, json[attr]
        when 'recipient_nick'
          assert_equal message.recipient.nick, json[attr]
        else
          assert_serialized_value message.send(attr).as_json, json[attr]
        end
      end
    end

    assert_template :index
    assert_template partial: "api/v1/messages/_minimal_message"
  end

  def test_show
    dinnerbone = Player.find_by_nick('Dinnerbone')
    message = dinnerbone.messages.last
    get :show, params: { id: message.id, format: :json }
    assert_response 200
    @attributes.each do |attr|
      case attr
      when 'author_nick'
        assert_equal message.author.nick, response_json[attr]
      when 'recipient_nick'
        assert_equal message.recipient.nick, response_json[attr]
      else
        assert_serialized_value message.send(attr).as_json, response_json[attr]
      end
    end

    assert_template :show
    assert_template partial: "api/v1/messages/_minimal_message"
  end

private
  def assert_serialized_value(expected, actual)
    expected.nil? ? assert_nil(actual) : assert_equal(expected, actual)
  end
end
