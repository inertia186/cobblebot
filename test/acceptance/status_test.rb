require 'test_helper'

class StatusTest < ActionDispatch::IntegrationTest
  def setup
  end

  def test_basic_workflow
    full_status = {
      gametype: 'SMP',
      game_id: 'MINECRAFT',
      version: '15w47c',
      plugins: [],
      map: 'world',
      numplayers: '2',
      maxplayers: '20',
      hostport: '25565',
      hostip: '127.0.0.1',
      motd: '\xA7bMinecraft\xA7r \xB6',
      players: ['inertia186', 'Dinnerbone'],
      raw_plugins: '',
      server: nil,
      timestamp: Time.now
    }

    Server.mock_mode(up: true) do
      ServerQuery.mock_mode(full_query: full_status) do
        visit '/status'
        timestamp_format = '"%Y-%m-%dT%H:%M:%S.000Z"'

        full_status.each_with_index do |pair, index|
          key, value = pair
          nth = index + 1

          expected_name = case key
            when 'gametype' then 'Game Type'
            when 'game_id' then 'Game ID'
            when 'version' then 'Version'
            when 'plugins' then 'Plugins'
            when 'map' then 'Map'
            when 'numplayers' then 'No. of Players'
            when 'maxplayers' then 'Max No. of Players'
            when 'hostip' then 'Host IP'
            when 'motd' then 'Message of the Day'
            when 'rawplugins' then 'Raw Plugins'
            when 'server' then 'Server'
            when 'timestamp' then 'Timestamp'
            else @key
          end

          expected_value = case key
          when :plugins then 'None'
          when :raw_plugins then 'None'
          when :server then 'N/A'
          when :players then '["inertia186","Dinnerbone"]'
          when :timestamp then value.in_time_zone(Time.zone).strftime(timestamp_format)
          else value
          end

          css_path = "table > tbody > tr:nth-child(#{nth}) > th"

          result_name = within :css, css_path do
            assert page.has_content?(expected_name), "expect row ##{nth} to contain: #{expected_name}"
            page.evaluate_script("angular.element('#{css_path}').html();")
          end

          css_path = "table > tbody > tr:nth-child(#{nth}) > td"

          result_value = within :css, css_path do
            assert page.has_content?(expected_value), "expect cell ##{nth} to contain: #{expected_value}"
            page.evaluate_script("angular.element('#{css_path}').html();")
          end

          assert_equal expected_value, result_value,
            "expect {#{key}: #{value}} to yield #{expected_value}, but instead, we got: {#{result_name}: #{result_value}}"
        end
        save_screenshot
      end
    end
  end
end
