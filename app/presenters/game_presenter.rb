class GamePresenter
  attr_reader :game, :user, :form
  delegate :to_partial_path, to: :game

  class_attribute :wait_time, default: 30

  def initialize(game, user, form = nil)
    @game = game
    @user = user
    @form = form || game.form_class.new(game: game.state)
  end

  def name = game.name
  def player = game.player_from_user(user)
  def user_turn? = game.user_turn?(user)
  def messages = player&.messages&.reverse
  def cards = player&.cards

  def finished? = game.finished_at.present?
  def won? = winner == user
  def winner = game.participants.find_by(winner: true)&.user
  def started? = game.started_at.present?
  def playable? = started? && !finished?

  def score_label
    raise NotImplementedError, "#{self.class} must implement #score_label"
  end

  def scoreboard
    ranked_players.each_with_index.map { |player, index| scoreboard_entry(player, index + 1) }
  end

  private

  def ranked_players
    game.state.players.sort_by { |player| [ winner_rank_key(player), score_rank_key(player) ] }
  end

  def winner_rank_key(player) = player.user_id == winner&.id ? 0 : 1
  def score_rank_key(player) = score_order == :desc ? -score_for(player) : score_for(player)

  def scoreboard_entry(player, rank)
    ScoreboardEntry.new(
      name: player.name,
      score: score_for(player),
      winner: player.user_id == winner&.id,
      rank: rank,
      you: player.user_id == user.id
    )
  end

  def score_for(player)
    raise NotImplementedError, "#{self.class} must implement #score_for"
  end

  def score_order
    raise NotImplementedError, "#{self.class} must implement #score_order"
  end
end
