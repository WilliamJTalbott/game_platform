class ScoreboardEntry
  attr_reader :name, :score, :rank

  def initialize(name:, score:, winner:, rank:, you:)
    @name = name
    @score = score
    @winner = winner
    @rank = rank
    @you = you
  end

  def winner? = @winner
  def you? = @you
end
