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
    target = ActionView::RecordIdentifier.dom_id(game)
    broadcast_replace(game, user, target, game_info.to_partial_path, game_info)
    broadcast_end_of_game_modal(game, user, game_info)
  end

  def self.broadcast_end_of_game_modal(game, user, game_info)
    return unless game_info.finished?

    broadcast_replace(game, user, "end_of_game_modal", "games/end_of_game_modal", game_info)
  end

  def self.broadcast_replace(game, user, target, partial, game_info)
    Turbo::StreamsChannel.broadcast_replace_to(game, user, target:, partial:, locals: { game_info: })
  end
end
