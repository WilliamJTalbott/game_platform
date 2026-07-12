class CrazyEightsGamePresenter

  attr_reader :game, :user

  def initialize(game, user)
    @game = game
    @user = user
  end

  def name = game.name
  def player = game.player_from_user(user)
  def user_turn? = game.user_turn?(user)

  def cards = player.cards
  def active_card = game.state.discard.active_card
  def messages = player.messages.reverse

  def started?
    game.started_at.present?
  end

  # ASK JOSH

  def to_partial_path
    "crazy_eights_games/crazy_eights_game"
  end

end
