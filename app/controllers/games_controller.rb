class GamesController < ApplicationController
  
  def history
    render :history
  end

  def index
    @user_games = Current.games.where(finished_at: nil)
    @other_games = Game.where(started_at: nil) - @user_games
  end

  def new
    @game = Game.new
  end

def show
  @game = Game.find(params[:id])
  @started = @game.started_at.present?
  @current_player = @game.player_from_user(Current.user)
  @cards = @current_player&.cards || []
end

def create
  @game = Game.new(game_params)
  @participant = @game.participants.new(user: Current.session.user)

  @game.initialize_game

  if @game.save
    redirect_to @game
  else
    render :new
  end
end

  def start
    @game = Game.find(params[:id])

    if @game.can_start?
      @game.start
      @game.save
    end

    redirect_to @game
  end

  
  private

  def game_params
    params.require(:game).permit( :name, :game_type )
  end

end
