class BroadcastGameJob < ApplicationJob
  queue_as :default

  def perform(game)
    game.users.each do |user|
      GameTurboUpdate.broadcast(game, user)
    end
  end
end
