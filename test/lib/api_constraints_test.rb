require 'test_helper'
require 'api_constraints'

class ApiConstraintsTest < ActiveSupport::TestCase
  Request = Struct.new(:headers)

  def test_nondefault_version_does_not_match_a_missing_accept_header
    refute constraint.matches?(request(nil))
  end

  def test_matches_only_the_complete_versioned_media_type
    assert constraint.matches?(request('application/vnd.cobblebot.v1'))
    refute constraint.matches?(request('application/vnd.cobblebot.v10'))
  end

  def test_matches_parameterized_and_comma_separated_media_types
    assert constraint.matches?(request(
      'application/json, application/vnd.cobblebot.v1; charset=utf-8; q=0.8'
    ))
    refute constraint.matches?(request('application/vnd.cobblebot.v1; q=0'))
  end

  def test_quoted_parameter_delimiters_do_not_become_quality_parameters
    assert constraint.matches?(request(
      'application/vnd.cobblebot.v1; profile="a;q=0,b"'
    ))
    refute constraint.matches?(request(
      'application/vnd.cobblebot.v1; profile="a;q=1,b"; q=0'
    ))
  end

  def test_default_version_matches_without_an_accept_header
    default = ApiConstraints.new(version: 1, default: true)

    assert default.matches?(request(nil))
  end

private
  def constraint
    @constraint ||= ApiConstraints.new(version: 1, default: false)
  end

  def request(accept)
    Request.new({'Accept' => accept})
  end
end
