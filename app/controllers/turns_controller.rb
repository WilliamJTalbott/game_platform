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

  # Two streams: the game re-renders from unchanged state, and the flash says why
  # the turn was refused. Without the second one the form's errors are computed,
  # handed to the presenter, and never shown — the turn just fails silently.
  def render_invalid_turn
    render turbo_stream: [
      GameTurboUpdate.stream(turbo_stream, @game, current_user, form: @form),
      flash_stream(@form.errors.full_messages.to_sentence.upcase_first)
    ], status: :unprocessable_content
  end

  def flash_stream(message)
    turbo_stream.replace("flash", partial: "shared/flash", locals: { message: message })
  end

  def render_finished_game
    render turbo_stream: turbo_stream.replace(
      "end_of_game_modal",
      partial: "games/end_of_game_modal",
      locals: { game_info: @game.presenter(current_user) }
    ), status: :unprocessable_content
  end
end
