json.(@pvps) do |pvp|
  json.id pvp.id
  json.body pvp.body
  json.created_at pvp.created_at

  json.loser do
    json.nick pvp.recipient.nick
    json.quote pvp.loser_quote
  end

  json.winner do
    json.nick pvp.author.nick
    json.quote pvp.winner_quote
  end
end
