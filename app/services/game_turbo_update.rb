class GameTurboUpdate
  def self.stream(turbo_stream, game, user, form:)
    game_info = game.presenter(user, form)

    turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(game),
      partial: game_info.to_partial_path,
      locals: { game_info: }
    )
  end

  def self.broadcast(game, user)
    game_info = game.presenter(user)

    Turbo::StreamsChannel.broadcast_replace_to(
      game,
      user,
      target: ActionView::RecordIdentifier.dom_id(game),
      partial: game_info.to_partial_path,
      locals: { game_info: }
    )
  end
end
