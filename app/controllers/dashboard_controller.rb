class DashboardController < ApplicationController
  def index
    if current_user
      @user = current_user
    else
      render 'public'
    end
  end

  
  def about
  end
 
end
