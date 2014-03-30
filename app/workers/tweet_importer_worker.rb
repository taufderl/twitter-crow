class TweetImporterWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  
  sidekiq_options retry: false
  
  def perform(user_id)
    at 0, 100, 'starting'
    user = User.find(user_id)
    
    if user.tweets_updated?
      at 100, 100, 'already up to date'
    else
      user.tweets_updated = Time.now
      # update tweets and safe user
      at 10, 100, 'fetching tweets...'
      retrieved_tweets = fetch_all_tweets(user.name)
      
      #puts retrieved_tweets
      
      at 70, 100, 'processing Tweets...'
      new_tweets = []
      retrieved_tweets.each do |tweet|
        new_tweets << new_tweet = Tweet.new
        
        new_tweet.id = tweet.id
        new_tweet.user = user
        new_tweet.created_at = tweet.created_at
        new_tweet.screen_name = tweet.user.username
        new_tweet.text = tweet.text
        new_tweet.geo_enabled = true ? tweet.geo?: false
        new_tweet.geo_latitude = tweet.geo.coordinates[0]
        new_tweet.geo_longitude = tweet.geo.coordinates[1]
      end
      
      at 80, 100, 'saving Tweets...'
      Tweet.transaction do
        new_tweets.each do |t|
          t.save
        end         
      end    
      # if all worked save user
      user.save
      
      at 100, 100, 'finished!'
    end
  end
  
  private
  
  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield max_id
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end
  
  def fetch_all_tweets(user)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
    end
  
    begin
      collect_with_max_id do |max_id|
        options = {:count => 200, :include_rts => true}
        options[:max_id] = max_id unless max_id.nil?
        @client.user_timeline(user, options)
      end
    rescue Exception => e
      return false => e
    end
  end
  
end