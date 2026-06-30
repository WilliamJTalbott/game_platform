class UserController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]

  def new
    render :new
  end

  def create
    
  end
end
