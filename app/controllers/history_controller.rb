class HistoryController < ApplicationController
  def index
    @games = Game.all
  end
end
