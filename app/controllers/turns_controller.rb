class TurnsController < ApplicationController

  def create
    @game = Game.find(params[:game_id])
    @game.action(params[:player], params[:rank])
    @game.save
    
    redirect_to @game
  end
  
end