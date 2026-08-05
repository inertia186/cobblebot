require 'test_helper'

class MinecraftQueryTimeoutCompatibilityTest < ActiveSupport::TestCase
  def test_query_exposes_timeout_to_its_singleton_methods
    assert Query.respond_to?(:timeout, true)
  end
end
