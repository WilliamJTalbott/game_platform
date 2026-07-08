class Game < ApplicationRecord
  has_many :participants
  has_many :users, through: :participants
  enum :game_type, { "Go Fish": 0, "Secret Hitler": 1 }

  serialize :go_fish, coder: GoFish::Game

  def start
    self.started_at = Time.current

    self.go_fish = GoFish::Game.new(game_players)
    go_fish.start
    save!
  end

  def action(player_name, rank)
    player = go_fish.players.find { |player| player.name == player_name }

    raise ArgumentError, "Invalid player" unless player
    go_fish.play_turn(player, rank)
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

  def game_players
    users.map { |user| GoFish::Player.new(user.id, user.email_address) }
  end

  def player_from_user(user)
    go_fish.players.find { |player| player.user_id == user.id }
  end

  def opponents(user)
    game_players.reject { |player| player.user_id == user.id }
  end

end
