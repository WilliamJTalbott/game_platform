class GamePresenter
  attr_reader :game, :user, :form, :wait_time
  delegate :to_partial_path, to: :game

  class_attribute :wait_time, default: 30

  def initialize(game, user, form = nil)
    @game = game
    @user = user
    @form = form || game.form_class.new(game: game.state)
  end
end
