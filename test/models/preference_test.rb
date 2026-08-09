require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  def test_secure_keys_are_classified_server_side
    assert preferences(:web_admin_password).secure?
    assert preferences(:irc_nickserv_password).secure?
    assert Preference.new(key: Preference::ORIGIN_SALT).secure?
    assert Preference.new(key: Preference::DB_IP_API_KEY).secure?
    assert Preference.new(key: Preference::MMP_API_KEY).secure?
    refute preferences(:motd).secure?
  end

  def test_to_param
    Preference.all.find_each do |p|
      assert p.to_param, "expect param"
    end
  end
  
  def test_web_admin_password
    assert Preference.web_admin_password, "did expect web admin to be set"
  end

  def test_provision_web_admin_password_requires_a_secret_for_a_new_database
    Preference.where(key: Preference::WEB_ADMIN_PASSWORD).delete_all

    error = assert_raises(ArgumentError) do
      Preference.provision_web_admin_password!(environment: {})
    end

    assert_includes error.message, Preference::WEB_ADMIN_PASSWORD_ENV
    refute Preference.exists?(key: Preference::WEB_ADMIN_PASSWORD)
  end

  def test_provision_web_admin_password_uses_the_operator_secret
    Preference.where(key: Preference::WEB_ADMIN_PASSWORD).delete_all

    preference = Preference.provision_web_admin_password!(environment: {
      Preference::WEB_ADMIN_PASSWORD_ENV => 'operator-supplied-secret'
    })

    assert_predicate preference, :persisted?
    assert_equal 'operator-supplied-secret', preference.value
  end

  def test_provision_web_admin_password_preserves_an_existing_secret
    preference = preferences(:web_admin_password)
    preference.update!(value: 'already-rotated-secret')

    result = Preference.provision_web_admin_password!(environment: {
      Preference::WEB_ADMIN_PASSWORD_ENV => 'replacement-secret'
    })

    assert_equal preference, result
    assert_equal 'already-rotated-secret', preference.reload.value
  end

  def test_retired_slack_keys_are_not_supported
    refute_includes Preference::ALL_KEYS, 'slack_api_key'
    refute_includes Preference::ALL_KEYS, 'slack_group'

    Preference.find_or_create_all

    refute Preference.exists?(key: 'slack_api_key')
    refute Preference.exists?(key: 'slack_group')
  end

  def test_path_to_server
    Preference.find_or_create_all

    assert_equal '/path/to/minecraft/server', Preference.path_to_server, "did expect default path to be set"
  end

  def test_find_or_create_all_always_returns_a_relation
    existing = Preference.find_or_create_all
    Preference.where(key: Preference::ALL_KEYS.first).delete_all
    provisioned = Preference.find_or_create_all

    assert_kind_of ActiveRecord::Relation, existing
    assert_kind_of ActiveRecord::Relation, provisioned
    assert_equal Preference::ALL_KEYS.sort, provisioned.pluck(:key).sort
  end

  def test_missing_method
    assert Preference.none, "expect method to exist"

    error = assert_raises(NoMethodError) do
      Preference.method_that_does_not_exist
    end
    assert_equal :method_that_does_not_exist, error.name
    assert_same Preference, error.receiver
  end
end
