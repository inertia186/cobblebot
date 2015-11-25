require "test_helper"

class PvpsTest < ActionDispatch::IntegrationTest
  def setup
    def Server.up?
      true
    end
    
    Message::Pvp.create(body: 'Dinnerbone was shot by Dinnerbone', recipient: players(:Dinnerbone), author: players(:Dinnerbone))
  end
  
  def test_basic_workflow
    visit '/pvps'
    fill_in 'query', with: 'dinnerbone'
    save_screenshot
  end
end