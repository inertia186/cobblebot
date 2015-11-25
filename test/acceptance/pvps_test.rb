require "test_helper"

class PvpsTest < ActionDispatch::IntegrationTest
  def setup
  end
  
  def test_basic_workflow
    visit '/pvps'
  end
end