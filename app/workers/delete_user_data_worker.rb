class DeleteUserDataWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: false
  
  def perform(user_id)
    user = User.find(user_id)
    user.destroy
  end
end