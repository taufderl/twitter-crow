class AjaxController < ApplicationController

  require 'marky_markov'
  
  # GET
  # starts a worker to crawl the twitter tweets
  def crawl_user_tweets
    if not user = current_user
      username = params[:username]
      user = User.new(name: username)
      user.save
      session[:user_id] = user.id #sets current user
    end
    job_id = UserTweetsImporterWorker.perform_async(user.id)
    render text: job_id
  end
  
  # GET
  # starts a worker to run the geoclustering on the tweets
  def run_geoclustering
    job_id = GeoClusteringWorker.perform_async({'user_id' => current_user.id})
    render text: job_id
  end
  
  # GET
  # starts a worker to crawl the nearby tweets
  def crawl_nearby_tweets
    current_location = session[:current_location].values
    job_id = NearbyTweetsImporterWorker.perform_async({'user_id' => current_user.id, 'current_location' => current_location})
    render text: job_id
  end
  
  # GET
  # starts a worker to run the markov language modeling worker
  def run_language_modeling
    current_cluster = session[:current_cluster]
    job_id = LanguageModelWorker.perform_async({'user_id' => current_user.id, 'current_cluster' => current_cluster})
    render text: job_id
  end
  
  # GET
  # returns a worker status for a given worker id
  def worker_status 
    job_id = params[:job_id]
    puts "JOBID #{job_id} \\JOBID"
    status = Sidekiq::Status::get_all job_id
    puts "STATUS #{status} \\STATUS"
    render json: status
  end
  
  # GET
  # returns all the tweets of a user in an array of tweet hashes
  def get_tweets
    result = []
    # do this workaround to convert id to an string, because it's
    # too big for an java script integer
    if current_user
      tweets = current_user.tweets
      tweets.each do |t|
        attributes = t.attributes
        attributes[:id] = t.id.to_s
        result << attributes
      end
    end
    render json: result.to_json
  end
  
  # POST
  # sets the current location and determines the corresponding cluster
  def set_current_location
    longitude = params[:lon]
    latitude = params[:lat]
    current_location = {lat: latitude, lon: longitude}
    session[:current_location] = current_location
    
    # determine the current cluster
    current_coordinates = current_location.values
    epsilon = Setting.get('dbscan.epsilon')
    neighbours = []
    current_user.tweets_with_geo.each do |tweet|
      # calc distance and if smaller than epsilon add to neighbours
      distance = Math.sqrt(
                  ((tweet.coordinates[0]-current_location[:lat].to_f)**2) +
                  ((tweet.coordinates[1]-current_location[:lon].to_f)**2))
      neighbours.push(tweet.cluster) if distance < epsilon
    end
    # select most frequent neighbour
    # this is actually not the only solution, another approach would be to find the closest value
    if neighbours.any?
      cluster = neighbours.group_by { |c| c }.values.max_by { |values| values.size }.first
    else 
      cluster = -2
    end
    session[:current_cluster] = cluster
    render json: current_location.to_json
  end
  
  # POST
  # searches a location given any input string
  def search_location
    location = params[:location]
    ip_based_search = false
    # if string not empty
    if not location.empty?
      # find coordinates for the given location name
      result = Geocoder.search(location)
      # if successful
      if result.any?
        # take first result
        latitude = result[0].latitude
        longitude = result[0].longitude
      else
        # if no results try ip based
        ip_based_search = true
      end
    else
      # if search string empty try ip based
      ip_based_search = true
    end
    
    # if ip based search required
    if ip_based_search
      # get location from request IP
      geoip = request.location
      latitude = geoip.latitude
      longitude = geoip.longitude
    end
    render json: {lon: longitude, lat: latitude}.to_json
  end
  
  # GET
  # returns the current location from the session as json
  def get_current_location
    render json: session[:current_location].to_json
  end
  
  # GET
  # gets the generation explanation for a given user
  def generation_explanation
    @total_tweets = current_user.tweets.count
    @geo_tweets = current_user.tweets_with_geo.count
    @current_cluster = session[:current_cluster]
    @tweets_in_current_cluster = current_user.tweets_in_cluster(@current_cluster).count
    # count nearby tweets in file
    lines = File.open(current_user.id.to_s+'_nearby.tweets', 'r').readlines()
    @nearby_tweets = lines.count
  end
  
  # GET
  # generates a new tweet and returns it to be presented to the user
  def generate_next_tweet
    markov = MarkyMarkov::Dictionary.new(current_user.dictionary)
    new_tweet = markov.generate_n_words 10
    # TODO: make more sophisticated
    render text: new_tweet
  end
  
  # GET
  # reset session
  # TODO: make reset_session work!
  def reset_session
    DeleteUserDataWorker.perform_async(current_user.id)
    session[:user_id] = nil
    session[:current_cluster] = nil
    session[:current_location] = nil
    #reset_session
    current_user = nil
    redirect_to root_path
  end
end
