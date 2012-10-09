class ApplicationController < ActionController::Base
  before_filter :load_user
  protect_from_forgery
  
  def load_user
    if session[:player].nil?
      unless defined? @@player
        @@player = 0
      else
        @@player = 1
      end
      session[:player] = @@player
    end
    
    @player = session[:player]
  end
end
