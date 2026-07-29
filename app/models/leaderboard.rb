class Leaderboard
  WIN_PERCENT_MINIMUM_GAMES = 5
  DEFAULT_SORT = "games_won desc"
  TIE_BREAKERS = [ "games_played desc", "name asc" ].freeze
  PER_PAGE = 25
  # Kaminari turns `page` straight into an OFFSET with no upper bound, so `?page=99999999999`
  # overflows bigint and PG raises. Nothing in kaminari clamps it for us.
  MAX_PAGE = 10_000

  attr_reader :query, :page

  def initialize(params: nil, page: nil)
    @query = PlayerStat.where(games_played: 1..).ransack(params)
    apply_sorts_with_tie_breakers
    @page = page
  end

  def rows = query.result.page(bounded_page).per(PER_PAGE)

  private

  def bounded_page = page.to_s.to_i.clamp(1, MAX_PAGE)

  def apply_sorts_with_tie_breakers
    primary = query.sorts.find(&:valid?)&.then { "#{it.name} #{it.dir}" } || DEFAULT_SORT
    query.sorts.clear
    query.sorts = [ primary, *TIE_BREAKERS ].uniq { |sort| sort.split.first }
  end
end
