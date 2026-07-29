class LeaderboardPresenter
  SORT_BUTTONS = [
    { sort: "games_won desc",      label: "Wins",            icon: "trophy" },
    { sort: "games_played desc",   label: "Games Played",    icon: "cards" },
    { sort: "win_percentage desc", label: "Win Percentage",  icon: "percent",
      minimum_games: Leaderboard::WIN_PERCENT_MINIMUM_GAMES },
    { sort: "play_seconds desc",   label: "Time Played",     icon: "timer" }
  ].freeze

  def initialize(params:, page:, current_user:)
    @leaderboard = Leaderboard.new(params: params, page: page)
    @current_user = current_user
  end

  def query = @leaderboard.query
  def sort_buttons = SORT_BUTTONS
  def rows = @rows ||= @leaderboard.rows
  def empty? = rows.total_count.zero?

  def sorted_by?(button) = sorted_by_attribute?(button[:sort].split.first)

  # The form must round-trip the *primary* sort only. Binding the hidden field to the search
  # object's own `s` serializes all three Sort nodes to their `#<Ransack::Nodes::Sort:0x…>`
  # inspect strings, so the next filter submit carries an unparseable sort and the board
  # silently drops back to the default.
  def primary_sort = query.sorts.first&.then { "#{it.name} #{it.dir}" }

  def entries
    @entries ||= rows.each_with_index.map { |row, index| build_entry(row, rows.offset_value + index + 1) }
  end

  def win_percent_note
    return unless sorted_by_attribute?("win_percentage")

    "Win % ranks players with at least #{Leaderboard::WIN_PERCENT_MINIMUM_GAMES} finished games."
  end

  def empty_message
    return "#{win_percent_note} Nobody qualifies yet." if win_percent_note
    return "No player matches those filters." if query.conditions.any?

    "No games have finished yet — play one and you'll be first on the board."
  end

  private

  def sorted_by_attribute?(attribute) = query.sorts.first&.name == attribute

  def build_entry(row, rank)
    LeaderboardEntry.new(rank: rank, name: row.name, country: row.country, games_played: row.games_played,
      games_won: row.games_won, win_percentage: row.win_percentage, play_seconds: row.play_seconds,
      you: row.user_id == @current_user.id)
  end
end
