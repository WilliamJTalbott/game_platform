class GamesDashboardPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def greeting_name = user.name

  def your_games = waiting_on_me_first(rows_for(your_game_scope))
  def open_games = rows_for(open_game_scope)
  def history_path = Rails.application.routes.url_helpers.history_index_path

  private

  # Games waiting on the user lead the list. `partition` is stable, so everything else
  # keeps the scope's own order rather than reshuffling around the promoted rows.
  # Open games are never the user's turn, so only "your games" needs this.
  def waiting_on_me_first(rows)
    waiting, rest = rows.partition(&:your_turn?)
    waiting + rest
  end

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
