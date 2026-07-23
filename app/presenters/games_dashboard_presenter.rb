class GamesDashboardPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def greeting_name = user.name

  def stats_line
    "#{user.games_played} played · #{user.games_won} won · #{user.win_percentage}% win rate"
  end

  def your_games = rows_for(your_game_scope)
  def open_games = rows_for(open_game_scope)
  def history_path = Rails.application.routes.url_helpers.history_index_path

  private

  def rows_for(scope)
    scope.includes(:participants, :users).map { |game| GameRowPresenter.new(game, user) }
  end

  def your_game_scope
    user.games.where(finished_at: nil, deleted_at: nil)
  end

  def open_game_scope
    Game.waiting.where.not(id: user.game_ids)
  end
end
