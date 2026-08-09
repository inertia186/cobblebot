require 'test_helper'
require 'rake'
require 'minitest/mock'

class CobblebotTestTaskTest < ActiveSupport::TestCase
  def setup
    ApplicationTaskTestSupport.load
    coverage_task.reenable
    @original_gate = ENV['COBBLEBOT_COVERAGE_GATE']
    @original_hell = ENV['HELL_ENABLED']
  end

  def teardown
    ENV['COBBLEBOT_COVERAGE_GATE'] = @original_gate
    ENV['HELL_ENABLED'] = @original_hell
  end

  def test_sets_the_gate_and_delegates_to_the_complete_test_task
    delegated = Minitest::Mock.new
    delegated.expect :invoke, nil
    original_lookup = Rake::Task.method(:[])
    lookup = lambda { |name| name == 'test' ? delegated : original_lookup.call(name) }

    Rake::Task.stub(:[], lookup) { coverage_task.invoke }

    assert_equal '1', ENV['COBBLEBOT_COVERAGE_GATE']
    assert_equal '0', ENV['HELL_ENABLED']
    delegated.verify
  end

private
  def coverage_task
    Rake::Task['cobblebot:test:coverage']
  end
end
