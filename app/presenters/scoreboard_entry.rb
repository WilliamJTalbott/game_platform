class ScoreboardEntry
  attr_reader :name, :score

  def initialize(name:, score:, winner:)
    @name = name
    @score = score
    @winner = winner
  end

  def winner? = @winner
end
