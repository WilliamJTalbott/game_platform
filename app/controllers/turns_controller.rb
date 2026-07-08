class TurnsController < ApplicationController
  before_action :check_user_turn

  def create
    @game.play_turn(params[:player], params[:rank])
    @game.save
    
    redirect_to @game
  end

  def check_user_turn
    @game = Game.find(params[:game_id])

    unless @game.go_fish.active_player == @game.player_from_user(Current.user)
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
end