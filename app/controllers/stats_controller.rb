class StatsController < ApplicationController
  def index
    @presenter = StatsPresenter.new(user: current_user)
  end
end
