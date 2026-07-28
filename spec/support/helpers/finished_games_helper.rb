module FinishedGamesHelper
  def finished_game_for(user, duration: 1.hour, won: false)
    game = create(:finished_game, :go_fish, :many_participants, :has_participants, :with_duration,
      users: [ user ], duration: duration)
    game.participants.find_by!(user: user).update!(winner: true) if won
    game
  end
end
