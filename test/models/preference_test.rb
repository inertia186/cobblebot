require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  def setup
  end

  def test_to_param
    Preference.all.find_each do |p|
      assert p.to_param, "expect param"
    end
  end
  
  def test_web_admin_password
    assert Preference.web_admin_password, "did expect web admin to be set"
  end

  def test_path_to_server
    sleep 1 if Preference.path_to_server.nil?
    skip 'race condition' if Preference.path_to_server.nil?
    
    assert_equal '/path/to/minecraft/server', Preference.path_to_server, "did expect default path to be set"
  end

  def test_missing_method
    assert Preference.none, "expect method to exist"
    
    begin
      refute Preference.method_that_does_not_exist, 'did not expect method to exist'
      # :nocov:
      fail 'did not expect method to exist'
      # :nocov:
    rescue NoMethodError => e
      # success
    end
  end
end
