require 'test_helper'

class ServerPropertiesTest < ActiveSupport::TestCase
  def setup
    method = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
    
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_difficulty
    assert ServerProperties.difficulty, "did expect web admin to be set"
  end

  def test_keys_as_strings
    refute_equal [], ServerProperties.keys_as_strings, 'expect non-empty array'
  end

  def test_missing_method
    assert ServerProperties.itself, "expect method to exist"
    
    begin
      refute ServerProperties.method_that_does_not_exist, 'did not expect method to exist'
      # :nocov:
      fail 'did not expect method to exist'
      # :nocov:
    rescue NoMethodError => e
      # success
    end
  end
end
