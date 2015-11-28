require "test_helper"

class PvpsTest < ActionDispatch::IntegrationTest
  def setup
  end
  
  def test_basic_workflow
    Server.mock_mode(up: true) do
      pvps = Message::Pvp.order("messages.created_at desc")
      
      visit '/pvps'
      
      css_path = 'count-up > span'
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      assert_equal Message::Pvp.count, result.to_i
      
      index = 0
      
      pvps.find_each do |pvp|
        nth = index = index + 1
        
        css_path = "table > tbody > tr:nth-child(#{nth}) > td"
        result = page.evaluate_script("angular.element('#{css_path}').html();")
        refute_equal 'Searching ...', result
        assert_equal pvp.body, result

        css_path = "table > tbody > tr:nth-child(#{nth}) > td:nth-child(2)"
        result = page.evaluate_script("angular.element('#{css_path}').html();")
        assert_match pvp.recipient.nick, result

        css_path = "table > tbody > tr:nth-child(#{nth}) > td:nth-child(3)"
        result = page.evaluate_script("angular.element('#{css_path}').html();")
        assert_match pvp.author.nick, result
      end
      
      fill_in 'query', with: 'resnullius'
      pvps = pvps.where(author: players(:resnullius))

      css_path = 'count-up > span'
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      assert_equal pvps.count, result.to_i
      
      css_path = "table > tbody > tr:nth-child(1) > td"
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      refute_equal 'Dinnerbone was shot by Dinnerbone', result
    end
  end
  
  def test_basic_json
    Server.mock_mode(up: true) do
      visit '/pvps.json'
      assert_equal 'application/json; charset=utf-8', page.response_headers['Content-Type']
      refute_match '[]', page.source
      assert_match 'Dinnerbone', page.source
      assert_match 'resnullius', page.source
    end
  end
end
