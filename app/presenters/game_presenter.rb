class GamePresenter
  attr_reader :game, :user, :form, :wait_time
  delegate :to_partial_path, to: :game

  class_attribute :wait_time, default: 30

  def initialize(game, user, form = nil)
    @game = game
    @user = user
    @form = form || game.form_class.new(game: game.state)
  end

  def finished? = game.finished_at.present?
  def won? = winner == user
  def winner = game.participants.find_by(winner: true)&.user

  def scoreboard
    game.state.players.map { |player| scoreboard_entry(player) }
      .sort_by { |entry| entry.winner? ? 0 : 1 }
  end

  private

  def scoreboard_entry(player)
    ScoreboardEntry.new(name: player.name, score: score_for(player), winner: player.user_id == winner&.id)
  end

  def score_for(player)
    raise NotImplementedError, "#{self.class} must implement #score_for"
  end
end
