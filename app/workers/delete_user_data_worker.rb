class DeleteUserDataWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: false
  
  def perform(user_id)
    puts "deleting user #{user_id}"
    user = User.find(user_id)
    # delete dictionary
    MarkyMarkov::Dictionary.delete_dictionary!(user.dictionary)
    # delete nearby tweets
    begin
      File.delete(user_id.to_s + '_nearby.tweets')
    rescue
      pass
    end
    # finally delete all data in the database
    user.destroy
  end
end