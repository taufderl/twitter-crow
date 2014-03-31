class LanguageModelWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options retry: false
  
  def perform(parameters)
    user_id = parameters['user_id']
    current_cluster = parameters['current_cluster']

    user = User.find(user_id)
    markov = MarkyMarkov::Dictionary.new(user.dictionary)
    
    clustered_tweets = user.clustered_tweets
    tweets = user.tweets_in_cluster current_cluster
    
    tweets.each do |tweet|
      markov.parse_string tweet.text
    end
    
    puts markov.inspect
    markov.save_dictionary!
    
    at 100, 100, 'finished!'
  end
    
end