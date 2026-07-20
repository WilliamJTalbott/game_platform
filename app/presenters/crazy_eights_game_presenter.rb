class CrazyEightsGamePresenter < GamePresenter
  def name = game.name
  def player = game.player_from_user(user)
  def user_turn? = game.user_turn?(user)

  def cards = player.cards
  def active_card = game.state.discard.active_card
  def messages = player.messages.reverse
  def playable? = started? && !finished?

  def started?
    game.started_at.present?
  end

  private

  def score_for(player) = player.cards.count
end
