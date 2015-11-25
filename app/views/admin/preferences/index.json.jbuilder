json.(@preferences) do |preference|
  json.id preference.id
  json.key preference.key
  json.value preference.value
end
