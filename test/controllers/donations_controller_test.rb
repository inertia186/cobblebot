require 'test_helper'

class DonationsControllerTest < ActionController::TestCase
  def test_json_represents_a_donation_and_its_author
    get_index(format: :json)

    assert_response :success
    assert_equal 'application/json', response.media_type
    donation = JSON.parse(response.body).find do |item|
      item.dig('author', 'nick') == 'resnullius'
    end
    assert donation
    assert donation.fetch('body').present?
  end

  def test_index_uses_the_current_scheme_for_atom_autodiscovery
    @request.env['HTTPS'] = 'on'

    get_index

    assert_select 'link[rel="alternate"][type="application/atom+xml"]' do |links|
      assert_equal donations_url(format: :atom, protocol: 'https'), links.first['href']
    end
    assert_select 'td[colspan="3"]', text: 'Searching ...'
  end

  def test_index_does_not_build_an_image_until_an_author_exists
    get_index

    assert_select 'a[ng-if="donation.author"] img[ng-src*="donation.author.nick"]'
    assert_select 'span[ng-if="!donation.author"]', text: 'Anonymous'
  end

  def test_empty_atom_feed_has_a_title_and_updated_timestamp
    Message::Donation.delete_all

    get_index(format: :atom)

    assert_response :success
    document = Nokogiri::XML(response.body)
    namespace = { 'atom' => 'http://www.w3.org/2005/Atom' }
    assert_equal "#{ServerProperties.level_name.titleize} Donations",
      document.at_xpath('/atom:feed/atom:title', namespace).text
    assert document.at_xpath('/atom:feed/atom:updated', namespace).text.present?
  end

private
  def get_index(params = {})
    Server.mock_mode(up: true) { get :index, params: params }
  end
end
