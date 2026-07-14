class GamePresenter
  attr_reader :game, :user, :form
  delegate :to_partial_path, to: :game

  def initialize(game, user, form = nil)
    @game = game
    @user = user
    @form = form || game.form_class.new(game: game.state)
  end

end
