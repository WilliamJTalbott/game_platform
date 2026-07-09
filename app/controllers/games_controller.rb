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
  return unless @started
    @current_player = @game.player_from_user(Current.user)
    @messages = @current_player.messages.reverse
    @opponents = @game.opponents(Current.user)
    @opponent_names = @game.opponents(Current.user).map(&:name)
    @cards = @current_player&.cards
    @winner = @game.winner
    @ranks = @current_player.unique_cards.map(&:rank)
    @is_user_turn = @game.is_user_turn(Current.user)
end

def create

  value = params[:game][:type]
  type_class = "#{value}Game".delete(' ').constantize
  
  @game = type_class.new(game_params)
  @participant = @game.participants.new(user: Current.session.user)

  if @game.save
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

    redirect_to @game
  end

  
  private

  def game_params
    params.require(:game).permit( :name, :game_type )
  end
  
end
