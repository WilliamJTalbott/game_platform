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
    return redirect_to root_path unless viewer_can_access?

    if @game.started_at
      @game_info = @game.presenter(Current.session.user)
    else
      @lobby = GameLobbyPresenter.new(@game, Current.session.user)
    end
  end

  def create
    type_class = Game.from_type(params[:game][:type])
    return unprocessable_new(Game.new) unless type_class

    build_and_save_game(type_class)
  end

  def start
    @game = Game.find(params[:id])
    return redirect_to game_path(@game), alert: "Only the host can start this game." unless @game.host?(current_user)
    return redirect_to game_path(@game), alert: "Need at least 2 players to start." unless @game.start

    redirect_to game_path(@game)
  end

  private

  def viewer_can_access?
    return true if @game.users.include?(Current.session.user)

    @game.participants.create(user: Current.session.user).persisted?
  end

  def build_and_save_game(type_class)
    @game = type_class.new(game_params)
    @participant = @game.participants.new(user: Current.session.user, host: true)
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
