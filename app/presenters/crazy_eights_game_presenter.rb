class CrazyEightsGamePresenter < GamePresenter
  def active_card = game.state.discard.active_card
  def score_label = "Cards left"

  private

  def score_for(player) = player.cards.count
  def score_order = :asc
end
