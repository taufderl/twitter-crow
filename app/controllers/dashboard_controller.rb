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
  
  # GET
  # show mutual information
  def mi
    if current_user
      @mi = current_user.mutual_information
      @total = @mi.total
      @clusters = @mi.content.count
      @tables = @clusters/5
      if @clusters % 5 > 0
        @tables += 1
        @tables_fill = 5 - @clusters % 5
      end   
      
      @content = @mi.content.sort_by {|k,v| k.to_i}
      
      
    else
      redirect_to root_path
    end
  end
 
end
