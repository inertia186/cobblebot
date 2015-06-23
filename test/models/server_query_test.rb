require 'test_helper'

class ServerQueryTest < ActiveSupport::TestCase
  def setup
  end
  
  def test_full_query
    begin
      ServerQuery.full_query
      # :nocov:
      fail 'did not expect the full query to work'
      # :nocov:
    rescue StandardError => e
      # success
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