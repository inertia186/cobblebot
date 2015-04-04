require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  def setup
    method = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
  end
  
  def test_web_admin_password
    assert Preference.web_admin_password, "did expect web admin to be set"
  end

  def test_path_to_server
    assert Preference.path_to_server, "did expect path to be set"
  end

  def test_missing_method
    refute Preference.method_that_does_not_exist, "did not expect method to exist" rescue return
  end
end
