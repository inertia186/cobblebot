json.(@query) do |stat|
  json.key stat[0]
  json.value stat[1]
end
