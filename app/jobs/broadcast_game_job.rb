# app/jobs/game_broadcast_job.rb
class BroadcastGameJob < ApplicationJob
  queue_as :default

  def perform(game)
    game.users.each do |user|
      game_info = game.presenter(user)

      Turbo::StreamsChannel.broadcast_replace_to(
        game,
        user,
        target: ActionView::RecordIdentifier.dom_id(game),
        partial: game_info.to_partial_path,
        locals: { game_info: game_info }
      )
    end
  end
end