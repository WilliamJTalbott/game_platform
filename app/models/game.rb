class Game < ApplicationRecord
  has_many :participants
  has_many :users, through: :participants

  serialize :state, coder: GoFish::Game

  def start
    self.started_at = Time.current
    self.state = GoFish::Game.new(create_players)
    state.deal
    save!
  end

  def play_turn(player_name, rank)
    player = state.players.find { |player| player.name == player_name}
    state.play_turn(player, rank)
  end

  def can_start?
    participants.count >= 2 && started_at.nil?
  end

  def finish
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

  # def self.type_names
  #   self.subclasses.map(&:name)
  # end

  def player_from_user(user)
    self.state.players.find { |player| player.user_id == user.id }
  end

  def is_user_turn?(user)
    self.state.active_player == self.player_from_user(user)
  end

  def started
    self.started_at.present?
  end

  def messages(user)
    player_from_user(user).messages.reverse
  end

  def opponents(user)
    self.state.players - [ player_from_user(user) ]
  end

  def opponent_names(user)
    self.opponents(user).map(&:name)
  end

  def cards(user)
    player_from_user(user)&.cards
  end

  def winner
    self.participants.find_by(winner: true)&.user
  end

  def ranks(user)
    player_from_user(user).unique_cards.map(&:rank)
  end

  private

  def create_players
    users.map { |user| GoFish::Player.new(user.id, user.email_address) }
  end

end
