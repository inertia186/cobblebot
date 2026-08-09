require "test_helper"

class DonationsTest < AcceptanceTest
  def test_basic_workflow
    Server.mock_mode(up: true) do
      players(:resnullius).update!(last_chat: 'UNIQUE DONOR QUOTE')
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

      fill_in 'query', with: 'unique donor quote'
      assert page.has_content?('$10 from resnullius')

      fill_in 'query', with: 'dinnerbone'
      assert page.has_no_content?('$10 from resnullius')
      assert page.has_no_css?('count-up > span')
    end
  end

end
