class Leaderboard
  MINIMUM_GAMES_FOR_WIN_PERCENTAGE = 5

  SORTS = {
    "wins" => { games_won: :desc, games_played: :desc, name: :asc },
    "games" => { games_played: :desc, games_won: :desc, name: :asc },
    "win_percent" => { win_percentage: :desc, games_played: :desc, name: :asc },
    "time" => { play_seconds: :desc, games_played: :desc, name: :asc }
  }.freeze

  DEFAULT_SORT = "wins"
  PER_PAGE = 25

  attr_reader :sort, :page

  def initialize(sort: DEFAULT_SORT, page: nil)
    @sort = SORTS.key?(sort) ? sort : DEFAULT_SORT
    @page = page
  end

  def rows = qualifying.page(page).per(PER_PAGE)

  private

  def qualifying
    scope = PlayerStat.where(games_played: 1..).order(SORTS.fetch(sort))
    win_percent_sort? ? scope.where(games_played: MINIMUM_GAMES_FOR_WIN_PERCENTAGE..) : scope
  end

  def win_percent_sort? = sort == "win_percent"
end
