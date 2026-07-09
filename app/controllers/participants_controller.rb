class ParticipantsController < ApplicationController
  
  def create
    @game = Game.find(params[:game_id])
    @participant = @game.participants.new(user: Current.session.user)
    
    if @participant.save
      redirect_to game_path(@game)
    else
      redirect_to games_path
    end
  end

end