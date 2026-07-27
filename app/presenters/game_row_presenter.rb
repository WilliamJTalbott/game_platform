class GameRowPresenter
  attr_reader :game, :user
  delegate :name, :to_param, to: :game

  def initialize(game, user)
    @game = game
    @user = user
  end

  def title = game.name
  def type_label = game.class.label
  def player_count = "#{game.seat_count}/#{game.max_players}"
  def full? = game.full?
  def mine? = game.users.include?(user)
  def your_turn? = mine? && game.status == "started" && game.user_turn?(user)

  def cta
    return :view if mine?

    full? ? :full : :join
  end
end
