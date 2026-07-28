class HistoryPresenter
  attr_reader :game
  delegate :name, :duration, :to_partial_path, :to_param, to: :game

  def initialize(game)
    @game = game
  end

  def winner
    game.participants.find(&:winner?)&.user&.name
  end
end
