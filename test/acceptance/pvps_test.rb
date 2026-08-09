require "test_helper"

class PvpsTest < AcceptanceTest
  def test_basic_workflow
    Server.mock_mode(up: true) do
      related_quote_pvp = messages(:dinnerbone_killed_resnullius)
      Message::Quote.create!(
        body: 'UNIQUE LOSER QUOTE',
        author: players(:resnullius),
        created_at: related_quote_pvp.created_at + 1.second
      )
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

      fill_in 'query', with: 'unique loser quote'
      assert page.has_content?(related_quote_pvp.body)
    end
  end

end
