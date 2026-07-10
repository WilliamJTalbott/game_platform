class Game < ApplicationRecord
  has_many :participants
  has_many :users, through: :participants

  def start
    self.started_at = Time.current

    self.state = build_game
    state.deal
    save!
  end

  def play_turn(...)
    raise NotImplementedError, "#{self.class} must implement #play_turn"
  end

  def build_game
    raise NotImplementedError, "#{self.class} must implement #build_game"
  end

  def can_start?
    participants.count >= 2 && started_at.nil?
  end

  def finish
    self.finished_at = Time.current
    save!
  end

  def status
    return 'waiting' unless self.started_at
    return self.finished_at ? 'finished' : 'started'
  end

  def duration
    return unless self.started_at && self.finished_at

    total_seconds = (self.finished_at - self.started_at).to_i
    return unless total_seconds

    hours = total_seconds / 3600
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60

    [hours, minutes, seconds].map { |t| t.to_s.rjust(2, '0') }.join(':')
  end

  def player_from_user(user)
    state.players.find { |player| player.user_id == user.id }
  end

  def user_turn?(user)
    state.active_player == player_from_user(user)
  end

  def presenter(user)
    raise NotImplementedError, "#{self.class} must implement #presenter"
  end

  private

  def create_players
    raise NotImplementedError, "#{self.class} must implement #create_players"
  end

end
