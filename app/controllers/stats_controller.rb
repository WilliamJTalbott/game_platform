class StatsController < ApplicationController
  def index
    @user = Current.user
  end
end