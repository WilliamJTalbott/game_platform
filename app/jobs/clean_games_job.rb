class CleanGamesJob < ApplicationJob
  queue_as :default

  def perform
    Game
      .where("created_at < ?", 3.days.ago)
      .where(deleted_at: nil)
      .update_all(deleted_at: Time.now)
  end
end
