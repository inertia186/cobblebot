require 'test_helper'

class StatusTest < AcceptanceTest
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
        display_names = {
          gametype: 'Game Type',
          game_id: 'Game ID',
          version: 'Version',
          plugins: 'Plugins',
          map: 'Map',
          numplayers: 'No. of Players',
          maxplayers: 'Max No. of Players',
          hostip: 'Host IP',
          motd: 'Message of the Day',
          raw_plugins: 'Raw Plugins',
          server: 'Server',
          timestamp: 'Timestamp'
        }

        assert_equal full_status.size + 1, page.all('table > tbody > tr').size

        full_status.each_with_index do |pair, index|
          key, value = pair
          nth = index + 1
          expected_name = display_names.fetch(key, key.to_s)

          expected_value = case key
          when :plugins then 'None'
          when :raw_plugins then 'None'
          when :server then 'N/A'
          when :players then '["inertia186","Dinnerbone"]'
          when :timestamp then value.year.to_s
          else value
          end

          result_name = find("table > tbody > tr:nth-child(#{nth}) > th").text
          result_value = find("table > tbody > tr:nth-child(#{nth}) > td").text

          assert_equal expected_name, result_name
          assert_includes result_value, expected_value.to_s,
            "expect {#{key}: #{value}} to include #{expected_value}, but got {#{result_name}: #{result_value}}"
        end
      end
    end
  end
end
