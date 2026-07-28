class StatsPresenter
  def initialize(user:)
    @stat = user.player_stat
  end

  def games_played = @stat.games_played
  def games_won = @stat.games_won
  def win_percentage = format("%.1f%%", @stat.win_percentage)
end
