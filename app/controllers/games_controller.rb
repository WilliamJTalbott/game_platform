class GamesController < ApplicationController
  def history
    render :history
  end

  def index
    @dashboard = GamesDashboardPresenter.new(Current.user)
  end

  def new
    @game = Game.new
  end

  def show
    @game = Game.find(params[:id])
    @game_info = @game.presenter(Current.session.user)
  end

  def create
    type_class = Game.from_type(params[:game][:type])
    return unprocessable_new(Game.new) unless type_class

    build_and_save_game(type_class)
  end

  def start
    @game = Game.find(params[:id])
    return redirect_to game_path(@game) if @game.start

    render :show, status: :unprocessable_content
  end

  private

  def build_and_save_game(type_class)
    @game = type_class.new(game_params)
    @participant = @game.participants.new(user: Current.session.user)
    return redirect_to game_path(@game) if @game.save

    unprocessable_new(@game)
  end

  def unprocessable_new(game)
    @game = game
    render :new, status: :unprocessable_content
  end

  def game_params
    params.require(:game).permit(:name)
  end
end
