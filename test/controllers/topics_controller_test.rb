require 'test_helper'

class TopicsControllerTest < ActionController::TestCase
  def test_index_keeps_topic_rows_inside_tbody
    Message::Topic.create!(body: 'Current topic', author: players(:inertia186))
    Message::Topic.create!(body: 'Past topic', author: players(:Dinnerbone), created_at: 1.day.ago)
    @request.env['HTTPS'] = 'on'

    get_index

    assert_select 'link[rel="alternate"][type="application/atom+xml"]' do |links|
      assert_equal topics_url(format: :atom, protocol: 'https'), links.first['href']
    end
    assert_select 'table tbody > tr'
    assert_select 'table > tr', count: 0
    assert_select 'tbody th[colspan="3"]', text: /Past Topics/
  end

  def test_empty_atom_feed_has_a_title_and_updated_timestamp
    Message::Topic.delete_all

    get_index(format: :atom)

    assert_response :success
    document = Nokogiri::XML(response.body)
    namespace = { 'atom' => 'http://www.w3.org/2005/Atom' }
    assert_equal "#{ServerProperties.level_name.titleize} Topics",
      document.at_xpath('/atom:feed/atom:title', namespace).text
    assert document.at_xpath('/atom:feed/atom:updated', namespace).text.present?
  end

private
  def get_index(params = {})
    Server.mock_mode(up: true) { get :index, params: params }
  end
end
