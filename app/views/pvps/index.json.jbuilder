json.(@pvps) do |pvp|
  json.id pvp.id
  json.body pvp.body
  json.created_at pvp.created_at

  if pvp.recipient
    json.loser do
      json.nick pvp.recipient.nick
      json.quote pvp.loser_quote
    end
  else
    json.loser nil
  end

  if pvp.author
    json.winner do
      json.nick pvp.author.nick
      json.quote pvp.winner_quote
    end
  else
    json.winner nil
  end
end
