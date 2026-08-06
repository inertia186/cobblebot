require 'test_helper'

class ServerQueryTest < ActiveSupport::TestCase
  def setup
  end
  
  def test_full_query
    assert_raises(CobbleBotError) do
      ServerQuery.full_query
    end
  end
  
  def test_missing_method
    assert ServerQuery.itself, "expect method to exist"
  
    begin
      refute ServerQuery.method_that_does_not_exist, 'did not expect method to exist'
      # :nocov:
      fail 'did not expect method to exist'
      # :nocov:
    rescue NoMethodError => e
      # success
    rescue StandardError => e
      # success
    end
  end
end
