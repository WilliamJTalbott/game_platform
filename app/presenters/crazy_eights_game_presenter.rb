class CrazyEightsGamePresenter < GamePresenter
  def name = game.name
  def player = game.player_from_user(user)
  def user_turn? = game.user_turn?(user)

  def cards = player.cards
  def active_card = game.state.discard.active_card
  def messages = player.messages.reverse
  def score_label = "Cards left"

  private

  def score_for(player) = player.cards.count
  def score_order = :asc
end
