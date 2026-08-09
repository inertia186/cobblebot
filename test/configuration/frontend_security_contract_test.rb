require 'test_helper'

class FrontendSecurityContractTest < ActiveSupport::TestCase
  def test_chat_inserts_dynamic_values_through_text_nodes
    assert_includes application_script, 'document.createTextNode("<#{nick}> ")'
    assert_includes application_script, '.text(match[0]).appendTo(line)'
    refute_includes application_script,
      '@append "&lt;" + nick + "&gt; " + toAppend'
    assert_includes players_script, 'text = no_tags_text'
  end

  def test_form_errors_are_not_compiled_as_dynamic_markup
    assert_includes main_script, "list.append $('<li>').text(msg)"
    refute_includes main_script, '$compile(template)'
  end

  def test_cancel_on_navigate_cleans_up_and_preserves_unmanaged_failures
    assert_includes cancel_on_navigate_script, 'function removeTimeout(timeout)'
    assert_includes cancel_on_navigate_script,
      'HttpPendingRequestsService.removeTimeout(timeout);'
    assert_includes cancel_on_navigate_script,
      'var timeout = response && response.config && response.config.timeout;'
    assert_includes cancel_on_navigate_script,
      'if (timeout && timeout.isGloballyCancelled)'
    assert_includes cancel_on_navigate_script, 'return $q.reject(response);'
  end

  def test_polling_debounce_and_navigation_have_lifecycle_guards
    assert_includes application_script, "$('a#irc-link').length > 0"
    assert_includes pvp_script, '$timeout.cancel($scope.lastSearchId)'
    assert_includes player_navigation_script, ".removeAttr('href')"
    assert_includes player_navigation_script, "event.preventDefault()"
    assert_includes player_navigation_script, "attr('aria-disabled', 'true')"
  end

  def test_related_player_search_uses_one_normalizing_filter
    assert_equal 1, main_script.scan("filter('searchFor'").length
    assert_includes main_script, 'if angular.isString(value) then value.toLowerCase()'
    assert_includes main_script, '[item.author, item.loser, item.winner]'
    refute_includes donations_script, "filter('searchFor'"
    refute_includes pvp_script, "filter('searchFor'"
  end

  def test_preference_values_are_filtered_from_request_logs
    filter = ActiveSupport::ParameterFilter.new(
      Rails.application.config.filter_parameters
    )

    filtered = filter.filter(preference: { value: 'sentinel-secret' })

    assert_equal '[FILTERED]', filtered[:preference][:value]
  end

private
  def application_script
    @application_script ||= read('app/assets/javascripts/application.coffee')
  end

  def main_script
    @main_script ||= read('app/assets/javascripts/main.coffee')
  end

  def cancel_on_navigate_script
    @cancel_on_navigate_script ||= read('app/assets/javascripts/angularCancelOnNavigateModule.js')
  end

  def donations_script
    @donations_script ||= read('app/assets/javascripts/donations.coffee')
  end

  def pvp_script
    @pvp_script ||= read('app/assets/javascripts/pvps.coffee')
  end

  def player_navigation_script
    @player_navigation_script ||= read('app/views/admin/players/show.js.coffee')
  end

  def players_script
    @players_script ||= read('app/views/players/index.js.coffee')
  end

  def read(path)
    Rails.root.join(path).read
  end
end
