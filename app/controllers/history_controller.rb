class HistoryController < ApplicationController
  def index
    @games = current_user.games.finished.includes(participants: :user).map { |game| HistoryPresenter.new(game) }
  end
end
