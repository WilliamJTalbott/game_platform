class GamesController < ApplicationController
  
  def history
    render :history
  end

  def index
    @user_games = Current.games
    @other_games = Game.all - @user_games
  end

  def new
    @game = Game.new
  end

  def show
    @game = Game.find(params[:id])
  end

  # TODO ASK JOSH
  def create
    @game = Game.new(game_params)
    @player = @game.players.new(user: Current.session.user)
    @player.save

    if @game.save
      redirect_to @game
    else
      render :new
    end
  end

  def join
    @game = Game.find(params[:id])
    redirect_to @game
  end
  
  private

  def game_params
    params.require(:game).permit( :name, :game_type )
  end

end
