json.(@messages) do |message|
  json.partial! 'api/v1/messages/minimal_message', message: message
end
