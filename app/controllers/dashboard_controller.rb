class DashboardController < ApplicationController
  
  # GET
  # main page of the application
  def index
    if current_user
      @user = current_user
    else
      render 'public'
    end
  end

  #GET
  # about page of the application
  def about
  end
  
  # DELETE
  # delete all data of the current user and resets the session
  def logout
    DeleteUserDataWorker.perform_async(current_user.id)
    reset_session
    redirect_to root_path
  end
 
end
