json.array!(@tweets) do |tweet|
  json.extract! tweet, :id, :created_at, :text, :screen_name, :geo_longitude, :geo_latitude
  json.url tweet_url(tweet, format: :json)
end
