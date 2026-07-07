class Game < ApplicationRecord
  has_many :participants

  enum :game_type, { "Go Fish": 0, "Secret Hitler": 1 }

  def build_game
    GoFish::Game.load(state) || GoFish::Game.new(game_players)
  end

  def save_game(game)
    self.state = game.as_json
  end

  def initialize_game
    game = GoFish::Game.new(game_players)
    save_game(game)
  end

  def start
    self.started_at = Time.current

    game = build_game
    game.players = game_players
    game.start

    save_game(game)
  end

  def can_start?
    participants.count >= 2 && started_at.nil?
  end

  def end
    self.finished_at = Time.current
  end

  def status
    return 'waiting' unless self.started_at
    return self.finished_at ? 'finished' : 'started'
  end

  def duration

    return unless self.started_at && self.finished_at

    total_seconds = (self.started_at - self.finished_at).to_i
    return unless total_seconds

    hours = total_seconds / 3600
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60

    [hours, minutes, seconds].map { |t| t.to_s.rjust(2, '0') }.join(':')

  end

  def player_from_user(user)
    build_game.players.find do |player|
      player.user_id.to_i == user.id
    end
  end

  private

  def game_players
    participants.map do |participant|
      GoFish::Player.new(user_id: participant.user_id)
    end
  end

end
