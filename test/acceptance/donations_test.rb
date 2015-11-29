require "test_helper"

class DonationsTest < ActionDispatch::IntegrationTest
  def setup
  end

  def test_basic_workflow
    Server.mock_mode(up: true) do
      visit '/donations'

      assert page.has_no_content?('Searching ...')
      assert page.has_content?('$10 from resnullius')

      assert page.has_css?('count-up > span')
      within :css, 'count-up > span' do
        assert page.has_content?(Message::Donation.count)
      end

      within :css, "table > tbody > tr:nth-child(1) > td:nth-child(2)" do
        assert page.has_content?('resnullius')
      end

      fill_in 'query', with: 'dinnerbone'
      assert page.has_no_content?('$10 from resnullius')
      assert page.has_no_css?('count-up > span')
    end
  end

  def test_basic_json
    Server.mock_mode(up: true) do
      visit '/donations.json'
      assert_equal 'application/json; charset=utf-8', page.response_headers['Content-Type']
      refute_match '[]', page.source
      assert_match 'resnullius', page.source
    end
  end
end
