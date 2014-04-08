class NearbyTweetsImporterWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  
  sidekiq_options retry: false
  
  def perform(parameters)
    user_id = parameters['user_id']
    current_location = parameters['current_location'].map {|v| v.to_f }
    
    nearby_tweets = search_nearby_tweets(current_location)
    filename = user_id.to_s + '_nearby.tweets'
    File.open(filename, 'w') do |file|
      nearby_tweets.each do |t|
        file.write(t[:text]+"\n")
      end  
    end
  end
  
  private
  
  def search_nearby_tweets(location)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
    end
    radius = Setting.get('nearby_tweets.radius')
    location << radius
    geocode = location.join(',')
    puts geocode
    
    tweets = []
    search_result = @client.search("", :geocode => geocode,:result_type => "recent").each do |result|
      tweets << result
    end
    tweets
  end 
  
end