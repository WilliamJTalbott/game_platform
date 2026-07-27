class LeaderboardController < ApplicationController
  def index
    @presenter = LeaderboardPresenter.new(sort: params[:sort], current_user: current_user)
  end
end
