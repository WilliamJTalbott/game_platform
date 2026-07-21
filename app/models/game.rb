class Game < ApplicationRecord
  TYPES = %w[GoFishGame CrazyEightsGame].freeze

  after_create_commit -> { broadcast_refresh_to "games" }

  has_many :participants
  has_many :users, through: :participants

  scope :finished, -> { where.not(started_at: nil).where.not(finished_at: nil).order(finished_at: :desc) }
  scope :for_user, ->(user) { joins(:participants).where(participants: { user_id: user.id }) }

  def self.playable = TYPES.map(&:constantize)
  def self.from_type(name) = playable.find { it.name == name }
  def self.label = name.delete_suffix("Game").titleize
  def self.permitted_turn_params = []

  def start
    return false unless can_start?

    self.started_at = Time.current
    self.state = build_game
    state.deal
    save
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
  end

  def end_game(winner)
    participants.find_by!(user_id: winner.user_id).update!(winner: true)
    finish
  end

  def status
    return "waiting" unless self.started_at
    self.finished_at ? "finished" : "started"
  end

  def duration
    return unless self.started_at && self.finished_at

    total_seconds = (self.finished_at - self.started_at).to_i
    return unless total_seconds

    hours = total_seconds / 3600
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60

    [ hours, minutes, seconds ].map { |t| t.to_s.rjust(2, "0") }.join(":")
  end

  def player_from_user(user)
    state.players.find { |player| player.user_id == user.id }
  end

  def user_turn?(user)
    state.active_player == player_from_user(user)
  end

  def presenter(user, form = nil)
    raise NotImplementedError, "#{self.class} must implement #presenter"
  end

  def form_class
    raise NotImplementedError, "#{self.class} must implement #form_class"
  end

  private

  def create_players
    raise NotImplementedError, "#{self.class} must implement #create_players"
  end
end
