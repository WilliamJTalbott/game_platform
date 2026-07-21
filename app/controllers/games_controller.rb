class GamesController < ApplicationController
  def history
    render :history
  end

  def index
    @user_games = Current.games.where(finished_at: nil).where(deleted_at: nil)
    @other_games = Game.where(started_at: nil).where(deleted_at: nil) - @user_games
  end

  def new
    @game = Game.new
  end

def show
  @game = Game.find(params[:id])
  @game_info = @game.presenter(Current.session.user)
end

def create
  type_class = Game.from_type(params[:game][:type])

  if type_class
    build_and_save_game(type_class)
  else
    @game = Game.new
    render :new, status: :unprocessable_content
  end
end

  def start
    @game = Game.find(params[:id])

    if @game.start
      redirect_to game_path(@game)
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def build_and_save_game(type_class)
    @game = type_class.new(game_params)
    @participant = @game.participants.new(user: Current.session.user)

    if @game.save!
      redirect_to game_path(@game)
    else
      render :new
    end
  end

  def game_params
    params.require(:game).permit(:name)
  end
end
