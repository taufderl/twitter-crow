class GeoClusteringWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options retry: false
  
  def perform(parameters)
    at 1, 100, 'running DBScan...'
    user_id = parameters['user_id']
    user = User.find(user_id)
    
    # get settings
    epsilon = Setting.get('dbscan.epsilon')
    min_points = Setting.get('dbscan.min_points')
    puts "Using epsilon=#{epsilon} and min_points=#{min_points}"
    
    results = dbscan(user.coordinates,epsilon,min_points)
    
    n_clusters = results.size-1 # subtract one for noise (cluster -1), NOT TRUE: might not be any noise
    
    at 90, 100, 'applying clusters...'
    Tweet.transaction do
      results.each do |cluster, data|
        data.each do |id, coordinates|
          if id == 0
            current_cluster = cluster
            store current_cluster: cluster
          else
            tweet = Tweet.find(id)
            tweet.cluster = cluster
            tweet.save
          end
        end
      end
    end
    
    # if all worked update clustered timestamp
    user.geo_clustered = Time.now
    #user.current_cluster = current_cluster
    user.save
    
    # start mutual information calculation
    MutualInformationWorker.perform_async({user_id: user.id})
    
    at 100, 100, 'finished!'
  end
  
  
  private
  #DBSCAN
  
  def dbscan(points, epsilon=0.05, min_pts=2)
    @points, @epsilon, @min_pts = points, epsilon, min_pts

    # initialize points
    @new_points = []
    @points.each do |id, items|
      @new_points.push(Point.new(items, id))
    end
      # start dbscan
    _dbscan
  end

  def _dbscan
    clusters = {}     
    clusters[-1] = []
    current_cluster = -1
    size = @new_points.length
    for point, index in @new_points.each_with_index
      # add at thing here for number of points
      i = (index/size*90).to_i
      at i, 100, "point #{index} of #{size}"
      if not point.visited
        point.visited = true
        neighbours = immediate_neighbours(point)
        if neighbours.size >= @min_pts
          current_cluster += 1
          point.cluster = current_cluster                
          cluster = [point,]
          cluster.push(add_connected(neighbours,current_cluster))
          clusters[current_cluster] = cluster.flatten
        else
          clusters[-1].push(point)
        end
      end
    end 
    return as_list(clusters)
  end

  def as_list(clusters)
    hash = {}
    clusters.each do |key,points|
      cluster_hash = {}
      points.each do |point|
        cluster_hash[point.id] = point.items
      end
      hash[key] = cluster_hash
    end
    hash
  end
  
  def immediate_neighbours(point)
    neighbours = []
    @new_points.each do |p|
      next  if p.items == point.items
      d = distance(point.items,p.items)
      neighbours.push(p) if d < @epsilon
    end
    return neighbours
  end
  
  def distance(p1,p2)
    raise "Error" if p1.size != p2.size
    sum = 0
    (0...p1.size).each{|i| sum+=(p1[i]-p2[i])**2}
    Math.sqrt(sum)
  end
  
  def add_connected(neighbours,current_cluster)
    cluster_points = []
    neighbours.each do  |point|
      if not point.visited
        point.visited = true 
        new_points = immediate_neighbours(point)
        new_points.each do |p|
          if not neighbours.include? p
            neighbours.push(p) 
          end
        end  if new_points.size >= @min_pts 
      end

      if !point.cluster
        cluster_points.push(point)
        point.cluster = current_cluster
      end
    end
    return cluster_points
  end
  
  class Point
    attr_accessor :items,:id,:cluster,:visited
    def initialize(point, id)
      self.items = point
      self.id = id
      self.cluster = nil
      self.visited = false
    end
    def items_and_id
      return [self.items,self.id]
    end
  end
  
end