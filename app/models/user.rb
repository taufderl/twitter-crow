class User < ActiveRecord::Base

  TIMEOUT_TWEET_RELOAD = 1000
  TIMEOUT_GEO_CLUSTERING = 100

  has_many :tweets, dependent: :destroy
  
  def dictionary
    "#{id}"
  end
  
  def name_with_at
    return "@#{name}"
  end
  
  def tweets_updated?
    if tweets_updated.nil?
      return false
    end
    return Time.now - tweets_updated < TIMEOUT_TWEET_RELOAD
  end
  
   def geo_clustered?
    if geo_clustered.nil?
      return false
    end
    return Time.now - geo_clustered < TIMEOUT_GEO_CLUSTERING
  end
  
  def tweets_with_geo
    tweets_with_geo = []
    tweets.each do |t|
      tweets_with_geo << t if t.geo_enabled
    end
    return tweets_with_geo
  end
  
  def clustered_tweets
    clustered_tweets = {}
    tweets.each do |t|
      if clustered_tweets.include? t.cluster
        clustered_tweets[t.cluster] << t
      else
        clustered_tweets[t.cluster] = [t]
      end
    end
    return clustered_tweets
  end
  
  def tweets_in_cluster(cluster)
    tweets.select {|t| t.cluster == cluster}
  end
  
  def coordinates
    coordinates = {}
    tweets.each do |t|
      coordinates[t.id] = t.coordinates if t.geo_enabled
    end
    return coordinates
  end
end
