require "test_helper"

class TopicsTest < ActionDispatch::IntegrationTest
  def setup
  end

  def test_basic_workflow
    Server.mock_mode(up: true) do
      visit '/topics'

      css_path = "table > tbody > tr:nth-child(1) > td"
      result = page.evaluate_script("angular.element('#{css_path}').html();")
      refute_equal 'Searching ...', result
    end
  end

  # def test_basic_json
  #   Server.mock_mode(up: true) do
  #     visit '/topics.json'
  #     assert_equal 'application/json; charset=utf-8', page.response_headers['Content-Type']
  #     refute_match '[]', page.source
  #   end
  # end
end
