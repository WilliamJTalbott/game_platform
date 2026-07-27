class Leaderboard
  MINIMUM_GAMES_FOR_WIN_PERCENTAGE = 5

  SORTS = {
    "wins" => "games_won DESC, games_played DESC, users.name ASC",
    "games" => "games_played DESC, games_won DESC, users.name ASC",
    "win_percent" => "win_percentage DESC, games_played DESC, users.name ASC",
    "time" => "play_seconds DESC, games_played DESC, users.name ASC"
  }.freeze

  DEFAULT_SORT = "wins"

  attr_reader :sort

  def initialize(sort: DEFAULT_SORT)
    @sort = SORTS.key?(sort) ? sort : DEFAULT_SORT
  end

  def rows
    scope = base_scope.order(Arel.sql(SORTS.fetch(sort)))
    win_percent_sort? ? scope.having("COUNT(games.id) >= #{MINIMUM_GAMES_FOR_WIN_PERCENTAGE}") : scope
  end

  private

  def win_percent_sort? = sort == "win_percent"

  def base_scope
    User.joins(participants: :game)
      .where.not(games: { started_at: nil })
      .where.not(games: { finished_at: nil })
      .group("users.id")
      .select(select_list)
  end

  def select_list
    <<~SQL.squish
      users.id,
      users.name,
      COUNT(games.id) AS games_played,
      COUNT(*) FILTER (WHERE participants.winner) AS games_won,
      ROUND(COUNT(*) FILTER (WHERE participants.winner) * 100.0 / COUNT(games.id), 1) AS win_percentage,
      COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0)::bigint AS play_seconds
    SQL
  end
end
