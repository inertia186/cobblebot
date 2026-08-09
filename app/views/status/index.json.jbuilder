json.array!(@query) do |stat|
  key, value = stat.first
  json.key key
  json.value value
end
