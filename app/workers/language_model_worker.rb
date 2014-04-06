class LanguageModelWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options retry: false
  
  def perform(parameters)
    user_id = parameters['user_id']
    current_cluster = parameters['current_cluster']

    user = User.find(user_id)
    
    # make sure the new dictionary is empty 
    MarkyMarkov::Dictionary.delete_dictionary!(user.dictionary)
    markov = MarkyMarkov::Dictionary.new(user.dictionary)
    
    # parse all the tweets of the current cluster
    clustered_tweets = user.clustered_tweets
    tweets = user.tweets_in_cluster current_cluster
    
    # get weights for parsing tweets
    user_tweets_weight = Setting.get('model.user_tweets_weight')
    nearby_tweets_weight = Setting.get('model.nearby_tweets_weight')
    
    
    # parse all users tweets in current cluster
    tweets.each do |tweet|
      user_tweets_weight.times do
        markov.parse_string tweet.text
      end
    end
    
    # parse all the nearby tweets of the current location
    File.open(user.id.to_s+'_nearby.tweets', 'r').each do |line|
      nearby_tweets_weight.times do
        markov.parse_string line.strip
      end
    end
    
    markov.save_dictionary!
    at 100, 100, 'finished!'
  end
    
end