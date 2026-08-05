require 'test_helper'

class McSlapTest < ActiveSupport::TestCase
  class FirstChoiceRandom
    def rand(_limit)
      0
    end
  end

  def test_slap_can_use_a_deterministic_random_source
    assert_equal 'slaps Dinnerbone with a large piece of cobble',
      McSlap.slap('Dinnerbone', random: FirstChoiceRandom.new)
  end

  def test_combinations_preserve_the_original_phrase_space
    assert_equal 46_116, McSlap.combinations
  end

  def test_loading_and_using_the_service_is_silent
    output, errors = capture_io do
      McSlap.slap('Dinnerbone', random: FirstChoiceRandom.new)
    end

    assert_empty output
    assert_empty errors
  end
end
