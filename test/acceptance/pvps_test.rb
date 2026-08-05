require "test_helper"

class PvpsTest < AcceptanceTest
  def setup
  end

  def test_basic_workflow
    Server.mock_mode(up: true) do
      pvps = Message::Pvp.order("messages.created_at desc")

      visit '/pvps'

      assert page.has_css?('count-up > span'), 'expect counter showing'
      within :css, 'count-up > span' do
        assert page.has_content?(Message::Pvp.count), "expect counter now at: #{Message::Pvp.count}"
      end

      index = 0

      pvps.each do |pvp|
        nth = index = index + 1

        assert page.has_no_content?('Searching ...'), 'did not expect "Searching ..." text showing'
        assert page.has_content?(pvp.body), "expect results to contain: #{pvp.body}"

        within :css, "table > tbody > tr:nth-child(#{nth}) > td:nth-child(2)" do
          assert page.has_content?(pvp.recipient.nick), "expected result ##{nth} to contain loser: #{pvp.recipient.nick}"
        end

        within :css, "table > tbody > tr:nth-child(#{nth}) > td:nth-child(3)" do
          assert page.has_content?(pvp.author.nick), "expected result ##{nth} to contain winner: #{pvp.author.nick}"
        end
      end

      fill_in 'query', with: 'resnullius'
      pvps = pvps.where(recipient: players(:resnullius))

      within :css, 'count-up > span' do
        assert page.has_content?(pvps.count), "expect counter now at: #{pvps.count}"
      end

      assert page.has_no_content?('Dinnerbone was shot by Dinnerbone'), 'did not expect Dinnerbone listed as victim'
      assert page.has_content?('resnullius was killed by Dinnerbone using magic'), 'expect only resnullius listed as victim'
    end
  end

  def test_basic_json
    Server.mock_mode(up: true) do
      get pvps_path(format: :json)
      assert_response :success
      assert_equal 'application/json', response.media_type
      refute_equal [], JSON.parse(response.body)
      assert_match 'Dinnerbone', response.body
      assert_match 'resnullius', response.body
    end
  end
end
