class AjaxController < ApplicationController

  require 'marky_markov'
  
  # starts a worker to crawl the twitter tweets
  def crawl_tweets
    username = params[:username]
    if not user = User.find_by(name: username)
      user = User.new(name: username)
      user.save
    end
    session[:user_id] = user.id #sets current user
    job_id = TweetImporterWorker.perform_async(user.id)
    render text: job_id
  end
  
  # starts a worker to run the geoclustering on the tweets
  def run_geoclustering
    if session[:current_location]
      current_location = session[:current_location].values
    else
      current_location = [0,0]
    end
    job_id = GeoClusteringWorker.perform_async({'user_id' => current_user.id, 'current_location' => current_location})
    render text: job_id
  end
  
  # starts a worker to run the markov language modeling worker
  def run_language_modeling
    if session[:current_cluster]
      current_cluster = session[:current_cluster]
    else
      current_cluster = -1
    end
    
    job_id = LanguageModelWorker.perform_async({'user_id' => current_user.id, 'current_cluster' => current_cluster})
    render text: job_id
  end
  
  # returns a worker status for a given worker id
  def worker_status 
    job_id = params[:job_id]
    puts "JOBID #{job_id} \\JOBID"
    status = Sidekiq::Status::get_all job_id
    puts "STATUS #{status} \\STATUS"
    render json: status
  end
  
  
  def get_coordinates
    render json: current_user.coordinates.to_json
  end
  
  def get_clustered_tweets
    render json: current_user.clustered_tweets.to_json
  end
  
  def get_tweets
    result = []
    
    if current_user
      tweets = current_user.tweets
      tweets.each do |t|
        attributes = t.attributes
        attributes[:id] = t.id.to_s
        result << attributes
      end
    end
    render json: result.to_json
    #render json: current_user.tweets.to_json
  end
  
  def get_tweets_with_geo
    tweets = current_user.tweets_with_geo
    
    result = []
    tweets.each do |t|
      attributes = t.attributes
      attributes[:id] = t.id.to_s
      result << attributes
    end
    render json: result.to_json
    #render json: current_user.tweets.to_json
  end
  
  #post
  def set_current_location
    longitude = params[:longitude]
    latitude = params[:latitude]
    session[:current_location] = {}
    session[:current_location][:lat] = latitude
    session[:current_location][:lon] = longitude
    render json: [longitude, latitude]
  end
  
    
  def get_current_location
    render json: session[:current_location].to_json
  end
  
  #post
  def set_current_cluster
    current_cluster = params[:current_cluster].to_i
    session[:current_cluster] = current_cluster
    puts "CURRENT CLUSTER:"+current_cluster.to_s
    render json: current_cluster
  end
  
  def get_current_cluster
    render json: session[:current_cluster].to_json
  end
  
  def generation_explanation
    no_all = current_user.tweets.count
    tweets = current_user.tweets_with_geo
    no_with_geo = tweets.count
    
    tweets_in_current_cluster = current_user.tweets_in_cluster(session[:current_cluster])
    
    html = "Total tweets: <span class='badge'>#{no_all}</span><br />
            With Geodata: <span class='badge'>#{no_with_geo}</span><br />
            In current cluster: <span class='badge'>#{tweets_in_current_cluster.count}</span>"

    render text: html
  end
  
  def generate_next_tweet
    length = rand(7) + 3
    
    markov = MarkyMarkov::Dictionary.new(current_user.dictionary)
    new_tweet = markov.generate_n_words length
    
    render text: new_tweet
  end
  
  def reset_session
    redirect_to user_path(current_user.id), method: :delete
  end
end
