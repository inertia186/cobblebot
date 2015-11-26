require "test_helper"

class PvpsTest < ActionDispatch::IntegrationTest
  def setup
    Message::Pvp.create(body: 'Dinnerbone was shot by Dinnerbone', recipient: players(:Dinnerbone), author: players(:Dinnerbone))
  end
  
  def test_basic_workflow
    Server.mock_mode(up: true) do
      visit '/pvps'
      fill_in 'query', with: 'dinnerbone'
      save_screenshot
    end
  end
end
