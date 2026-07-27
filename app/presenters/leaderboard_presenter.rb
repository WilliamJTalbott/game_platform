class LeaderboardPresenter
  SORT_BUTTONS = [
    { key: "wins", label: "Wins", icon: "trophy" },
    { key: "games", label: "Games Played", icon: "cards" },
    { key: "win_percent", label: "Win %", icon: "percent" },
    { key: "time", label: "Time Played", icon: "timer" }
  ].freeze

  def initialize(sort:, current_user:)
    @leaderboard = Leaderboard.new(sort: sort)
    @current_user = current_user
  end

  def sort = @leaderboard.sort
  def sorted_by?(key) = sort == key
  def sort_buttons = SORT_BUTTONS
  def empty? = entries.empty?

  def entries
    @entries ||= @leaderboard.rows.each_with_index.map { |row, index| build_entry(row, index) }
  end

  def win_percent_note
    return unless sorted_by?("win_percent")

    "Win % ranks players with at least #{Leaderboard::MINIMUM_GAMES_FOR_WIN_PERCENTAGE} finished games."
  end

  def empty_message
    return "#{win_percent_note} Nobody qualifies yet." if sorted_by?("win_percent")

    "No games have finished yet — play one and you'll be first on the board."
  end

  private

  def build_entry(row, index)
    LeaderboardEntry.new(rank: index + 1, name: row.name, games_played: row.games_played,
      games_won: row.games_won, win_percentage: row.win_percentage, play_seconds: row.play_seconds,
      you: row.id == @current_user.id)
  end
end
