class MutualInformationWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  
  def perform(parameters)
   
    user_id = parameters['user_id']
    user = User.find(user_id)
    
    @clustered_tweets = user.clustered_tweets
    
    @clustered_wordcounts = Hash.new(0)
    @total_wordcounts = Hash.new(0)
    @cluster_words = Hash.new(0)
    @total_words = 0
    
    # count all words in all clusters
    count_words()
    
    # compute mutual information for each cluster
    @mutual_information = Hash.new(0)
    @mi = compute_mutual_information()
    
    
    @mutual_information.each do |cluster, words|
      @mutual_information[cluster] = words.sort_by{|w,mi| -mi}.first(10)
    end
    
    if mi = user.mutual_information
      mi.content = @mutual_information
      mi.total = @mi  
    else
      mi = MutualInformation.create(user: user, content: @mutual_information.sort, total: @mi)
    end
    mi.save
  end
  
  private
  
  # count words in given texts
  def count_words
    @clustered_tweets.each do |cluster, tweets|
      next if cluster == -1     # <--- Skip noise cluster!
      next if cluster == nil     # <--- Skip tweets without cluster!
      cluster_wordcounts = Hash.new(0)
      tweets.each do |tweet|
        tweet.text_cleaned.split.each do |token|
          cluster_wordcounts[token] += 1 
          @total_wordcounts[token] += 1
          @total_words += 1
          @cluster_words[cluster] += 1
        end
        @clustered_wordcounts[cluster] = cluster_wordcounts
      end
    end
  end
  
  # computes mutual information for given wordcounts
  def compute_mutual_information
    mi = 0
    @clustered_wordcounts.each do |cluster, words|
      @mutual_information[cluster] = {}
      words.each do |word, freq|
        begin
          p_cluster_word = @clustered_wordcounts[cluster][word] / @total_words.to_f
          p_cluster = @cluster_words[cluster] / @total_words.to_f
          p_word = @total_wordcounts[word] / @total_words.to_f
          log = Math.log(p_cluster_word/(p_cluster*p_word))
          cluster_word_mi = p_cluster_word * log

          @mutual_information[cluster][word] = cluster_word_mi
          mi += cluster_word_mi
        rescue
          logger.warn "[WARN] Divided by zero for \"#{word}\" in cluster #{cluster}"
          mutual_information[cluster][word] = 0
        end
      end
    end
    return mi
  end
end