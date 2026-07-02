class PlayersController < ApplicationController
  
  def create
    #TODO ASK JOSH
    @game = Game.find(params[:game_id])
    @player = @game.players.new(user: Current.session.user)
    
    if @player.save
      redirect_to @game
    else
      redirect_to games_path
    end
  end

end