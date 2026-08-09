require 'test_helper'

class CobbleBotErrorTest < ActiveSupport::TestCase
  def test_local_backtrace_includes_application_frames_from_the_cause
    cause = RuntimeError.new('failure')
    application_frame = Rails.root.join('app/models/example.rb').to_s
    cause.set_backtrace(["#{application_frame}:10", '/outside/gem.rb:20'])

    output = CobbleBotError.new(message: 'wrapped', cause: cause).local_backtrace

    assert_includes output, application_frame
    refute_includes output, '/outside/gem.rb:20'
  end
end
