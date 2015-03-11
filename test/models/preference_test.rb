require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  def test_web_admin_password
    refute Preference.web_admin_password, "did not expect web admin to be set"
    Preference.web_admin_password = '123456'
    assert Preference.web_admin_password, "did expect web admin to be set"
  end

  def test_path_to_server
    refute Preference.path_to_server, "did not expect path to be set"
    Preference.path_to_server = '/path/to/server'
    assert Preference.path_to_server, "did expect path to be set"
  end
end
