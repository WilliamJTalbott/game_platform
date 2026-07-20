class TurnsController < ApplicationController
  before_action :check_user_turn

  def create
    @form = @game.form_class.new(game_params.merge(game: @game.state))

    if @form.valid?
      play_turn
    else
      render_invalid_turn
    end
  end

  def check_user_turn
    @game = Game.find(params[:game_id])

    unless @game.status == "started" && @game.user_turn?(current_user)
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def game_params
    params.require(:turn).permit(:player_name, :rank, :card, :suit).to_h.symbolize_keys
  end

  private

  def play_turn
    @game.play_turn(**game_params)
    BroadcastGameJob.perform_now(@game)

    head :no_content
  end

  def render_invalid_turn
    render turbo_stream: GameTurboUpdate.stream(
      turbo_stream,
      @game,
      current_user,
      form: @form
    ), status: :unprocessable_entity
  end
end
