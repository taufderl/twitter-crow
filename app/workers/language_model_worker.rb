class LanguageModelWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options retry: false
  
  require 'uri'
  
  def perform(parameters)
    user_id = parameters['user_id']
    current_cluster = parameters['current_cluster']

    user = User.find(user_id)
    markov = MarkyMarkov::Dictionary.new(user.dictionary)
    
    # TODO: do for all clusters instead of only current one
    clustered_tweets = user.clustered_tweets
    tweets = user.tweets_in_cluster current_cluster
    
    tweets.each do |tweet|
      puts tweet.text, tweet.text.encoding
      markov.parse_string tweet.text
    end
    
    puts markov.inspect
    markov.save_dictionary!
    
    at 100, 100, 'saved the dictionary!'
  end
    
end