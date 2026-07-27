class LeaderboardEntry
  attr_reader :rank, :name, :games_played, :games_won

  def initialize(rank:, name:, games_played:, games_won:, win_percentage:, play_seconds:, you:)
    @rank = rank
    @name = name
    @games_played = games_played
    @games_won = games_won
    @win_percentage = win_percentage
    @play_seconds = play_seconds.to_i
    @you = you
  end

  def you? = @you

  def win_percentage = format("%.1f%%", @win_percentage)

  def play_time
    return "0m" if @play_seconds.zero?

    @play_seconds >= 3600 ? hours_and_minutes : minutes_and_seconds
  end

  private

  def hours_and_minutes
    "#{@play_seconds / 3600}h #{format("%02d", (@play_seconds / 60) % 60)}m"
  end

  def minutes_and_seconds
    "#{format("%02d", @play_seconds / 60)}m #{format("%02d", @play_seconds % 60)}s"
  end
end
