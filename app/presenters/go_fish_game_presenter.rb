
class GoFishGamePresenter

  attr_reader :game, :user

  def initialize(game, user)
    @game = game
    @user = user
  end

  def name = game.name
  def player = game.player_from_user(user)

  def user_turn? = game.user_turn?(user)

  def started?
    game.started_at.present?
  end

  def messages
    player.messages.reverse
  end

  def opponents
    game.state.players - [player]
  end

  def opponent_names
    opponents.map(&:name)
  end

  def cards
    player&.cards
  end

  def winner
    game.participants.find_by(winner: true)&.user
  end

  def ranks
    player.unique_cards.map(&:rank)
  end


  # ASK JOSH

  def to_partial_path
    "go_fish_games/go_fish_game"
  end

end
