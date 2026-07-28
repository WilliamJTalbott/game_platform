class LeaderboardController < ApplicationController
  def index
    @presenter = LeaderboardPresenter.new(sort: params[:sort], page: params[:page], current_user: current_user)
  end
end
