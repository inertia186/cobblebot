require 'test_helper'

class ServerQueryTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = Rails.root.join('tmp').to_s
  end
  
  def test_full_query
    assert_raises(CobbleBotError) do
      ServerQuery.full_query
    end
  end

  def test_query_retries_exceptions_and_non_hash_responses
    calls = 0
    sender = lambda do |*|
      calls += 1
      raise 'temporary failure' if calls == 1
      next 'not ready' if calls == 2

      {players: ['Dinnerbone']}
    end

    Query.stub(:simpleQuery, sender) do
      ServerQuery.stub(:try_max, 3) do
        assert_equal({players: ['Dinnerbone']}, ServerQuery.query)
      end
    end

    assert_equal 3, calls
  end
  
  def test_missing_method
    assert ServerQuery.itself, "expect method to exist"

    ServerQuery.mock_mode(full_query: {}) do
      assert_raises(NoMethodError) do
        ServerQuery.method_that_does_not_exist
      end
    end
  end
end
