class HistoryController < ApplicationController
  def index
    @games = Game.finished.for_user(current_user).includes(participants: :user).map { |game| HistoryPresenter.new(game) }
  end
end
