class GamesController < ApplicationController
  
  def history
    render :history
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      redirect_to game_path(@game)
    else
      render :new
    end
  end
  
  private

  def game_params
    params.require(:game).permit( :name, :game_type )
  end

end
