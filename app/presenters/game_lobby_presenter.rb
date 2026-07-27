class GameLobbyPresenter
  attr_reader :game, :user

  def initialize(game, user)
    @game = game
    @user = user
  end

  def name = game.name
  def type_label = game.class.label
  def player_count = "#{game.seat_count}/#{game.max_players}"
  def host_name = game.host&.name
  def can_start? = game.can_start?
  def host? = game.host?(user)
  def show_start? = host? && can_start?
  def invite_url = Rails.application.routes.url_helpers.game_url(game)

  def players
    game.participants.map do |participant|
      LobbyPlayerRow.new(name: participant.user.name, host: participant.host?, you: participant.user_id == user.id)
    end
  end

  def status_line
    return "Waiting for more players…" unless can_start?
    return "Lobby is full." if game.full?
    return "Ready when you are." if host?

    "Waiting for #{host_name} to start…"
  end
end
