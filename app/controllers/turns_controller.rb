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

  private

  def check_user_turn
    @game = Game.find(params[:game_id])
    return render_finished_game if @game.status == "finished"

    unless @game.status == "started" && @game.user_turn?(current_user)
      render json: { errors: [ "It's not your turn" ] }, status: :unprocessable_content
    end
  end

  def game_params
    params.require(:turn).permit(*@game.class.permitted_turn_params).to_h.symbolize_keys
  end

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
    ), status: :unprocessable_content
  end

  def render_finished_game
    render turbo_stream: turbo_stream.replace(
      "end_of_game_modal",
      partial: "games/end_of_game_modal",
      locals: { game_info: @game.presenter(current_user) }
    ), status: :unprocessable_content
  end
end
