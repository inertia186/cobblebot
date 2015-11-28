require "test_helper"

class DonationsTest < ActionDispatch::IntegrationTest
  def setup
  end
  
  def test_basic_workflow
    Server.mock_mode(up: true) do
      visit '/donations'
      
      css_path = "table > tbody > tr:nth-child(1) > td"
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      refute_equal 'Searching ...', result
      assert_equal '$10 from resnullius', result
      
      css_path = 'count-up > span'
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      assert_equal Message::Donation.count, result.to_i
      
      css_path = "table > tbody > tr:nth-child(1) > td:nth-child(2)"
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      assert_match 'resnullius', result
      
      fill_in 'query', with: 'dinnerbone'
      
      css_path = "table > tbody > tr:nth-child(1) > td"
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      refute_equal '$10 from resnullius', result
      
      css_path = 'count-up > span'
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      refute result
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
