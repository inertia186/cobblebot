json.(@reputations) do |reputation|
  json.partial! 'api/v1/reputations/reputation', reputation: reputation
end
