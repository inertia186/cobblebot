json.(@players) do |player|
  json.partial! 'api/v1/players/minimal_player', player: player
end
