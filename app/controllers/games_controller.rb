class GamesController < ApplicationController
  # before_action :set_game_class
  
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
end

def create
  type = params[:game][:type]
  type_class = "#{type}Game".delete(' ').constantize
  @game = type_class.new(game_params)
  @participant = @game.participants.new(user: Current.session.user)

  if @game.save!
    redirect_to game_path(@game)
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

    redirect_to game_path(@game)
  end

  
  private

  # def set_game_class
  #   @game_class = params[:type].constantize
  # end

  def game_params
    params.require(:game).permit( :name, :game_type )
  end
  
end
