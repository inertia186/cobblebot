json.(@donations) do |donation|
  json.id donation.id
  json.body donation.body
  json.created_at donation.created_at

  json.author do
    json.nick donation.author.nick
    json.quote donation.author.last_chat
  end
end
