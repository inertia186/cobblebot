require 'test_helper'

class PvpsControllerTest < ActionController::TestCase
  def test_index_uses_the_current_scheme_and_valid_colspan
    @request.env['HTTPS'] = 'on'

    get_index({}, format: :html)

    assert_select 'link[rel="alternate"][type="application/atom+xml"]' do |links|
      assert_equal pvps_url(format: :atom, protocol: 'https'), links.first['href']
    end
    assert_select 'td[colspan="4"]', text: 'Searching ...'
  end

  def test_json_represents_complete_and_missing_participants
    orphan = Message::Pvp.create!(body: 'An orphaned PVP record')

    get_index({}, format: :json)

    assert_response :success
    assert_equal 'application/json', response.media_type
    rendered = JSON.parse(response.body)
    complete = rendered.find { |pvp| pvp.dig('winner', 'nick') == 'Dinnerbone' }
    assert complete
    assert complete.dig('loser', 'nick').present?

    missing = rendered.find { |pvp| pvp['id'] == orphan.id }
    assert_nil missing['loser']
    assert_nil missing['winner']
  end

  def test_empty_atom_feed_has_a_title_and_updated_timestamp
    Message::Pvp.delete_all

    get_index({}, format: :atom)

    assert_response :success
    document = Nokogiri::XML(response.body)
    namespace = { 'atom' => 'http://www.w3.org/2005/Atom' }
    assert_equal "#{ServerProperties.level_name.titleize} PVPs",
      document.at_xpath('/atom:feed/atom:title', namespace).text
    assert document.at_xpath('/atom:feed/atom:updated', namespace).text.present?
  end

  def test_supported_sort_field_uses_a_qualified_column
    get_index(sort_field: 'body', sort_order: 'asc')

    assert_response :success
    assert_match(/ORDER BY messages\.body ASC/i, assigns(:pvps).to_sql)
  end

  def test_unknown_sort_field_safely_falls_back_to_created_at
    injection = 'messages.created_at; SELECT pg_sleep(1)'

    get_index(sort_field: injection, sort_order: 'asc')

    assert_response :success
    refute_includes assigns(:pvps).to_sql, injection
    assert_match(/ORDER BY messages\.created_at ASC/i, assigns(:pvps).to_sql)
  end

private
  def get_index(params = nil, format: :json, **keyword_params)
    params = (params || {}).merge(keyword_params)
    Server.mock_mode(up: true) do
      get :index, params: params.merge(format: format)
    end
  end
end
