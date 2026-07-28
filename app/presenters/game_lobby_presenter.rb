class GameLobbyPresenter
  attr_reader :game, :user

  def initialize(game, user)
    @game = game
    @user = user
  end

  def name = game.name
  def type_label = game.class.label
  def player_count = "#{game.seat_count}/#{game.max_players}"
  def open_seats = game.max_players - game.seat_count
  def can_start? = game.can_start?
  def host? = game.host?(user)
  def start_enabled? = host? && can_start?
  def invite_url = Rails.application.routes.url_helpers.game_url(game)

  # The Start button always renders, so its label carries the lobby's state — which is
  # why there is no separate status line. The roster already marks who the host is, so
  # the label doesn't need to name them.
  def start_label
    return "Start Game" if start_enabled?
    return "Waiting for players…" unless can_start?

    "Waiting for the host…"
  end

  def players
    game.participants.includes(:user).map do |participant|
      LobbyPlayerRow.new(name: participant.user.name, host: participant.host?, you: participant.user_id == user.id)
    end
  end
end
