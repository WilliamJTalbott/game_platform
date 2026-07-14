class CrazyEightsGamePresenter < GamePresenter

  def name = game.name
  def player = game.player_from_user(user)
  def user_turn? = game.user_turn?(user)

  def cards = player.cards
  def active_card = game.state.discard.active_card
  def messages = player.messages.reverse
  def finished? = game.finished_at.present?
  def playable? = started? && !finished?
  def winner = game.participants.find_by(winner: true)&.user

end
