class TurnsController < ApplicationController
  before_action :check_user_turn

  def create
    @game.play_turn(game_params[:player_name], game_params[:rank])
    @game.save
    
    redirect_to game_path(@game)
  end

  def check_user_turn
    @game = Game.find(params[:game_id])

    unless @game.is_user_turn?(current_user)
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def game_params
    params.require(:turn).permit(:player_name, :rank)
  end
  
end