class LeaderboardController < ApplicationController
  # `s` is ransack's sort key; the rest are the filter predicates the toolbar can send.
  QUERY_KEYS = [ :s, :name_i_cont, :country_eq, :games_played_gteq ].freeze

  def index
    @presenter = LeaderboardPresenter.new(
      params: search_params, page: params[:page], current_user: current_user
    )
  end

  private

  # `permit` (not `permit!`) is the whole guard. Ransack coerces a non-Hash `q` to `{}` by
  # itself, and declaring QUERY_KEYS as permitted *scalars* drops the shapes it would otherwise
  # raise on: a `q[s]` hash, a scalar `q[g]`, an array where a value belongs. Authorization is
  # still `PlayerStat.ransackable_attributes` — this only fixes shape. The null-byte strip is
  # the one thing no allowlist catches; PG raises on it and ransack passes it straight through.
  def search_params
    query = params.permit(q: QUERY_KEYS)[:q]
    query.transform_values { it.to_s.delete("\u0000") } if query.is_a?(ActionController::Parameters)
  end
end
