json.(@preferences) do |preference|
  json.id preference.id
  json.key preference.key
  json.secure preference.secure?
  if preference.secure?
    json.value nil
    json.has_value preference.value.present?
  else
    json.value preference.value
  end
end
