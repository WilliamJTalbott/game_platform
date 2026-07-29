return unless Rails.env.development?

include FactoryBot::Syntax::Methods

puts "Cleaning the database..."
User.destroy_all
Game.destroy_all

puts "Seeding database with FactoryBot..."

# Log in as 'me@example.com' / 'password' to view the end-of-game screens.
me = create(:user, email_address: "me@example.com", country: "US")
opponent = create(:user, email_address: "opponent@example.com", country: "CA")

# A finished Go Fish game you WON -> modal shows "You win".
create(:finished_game, :go_fish, :user_won, :has_participants,
       name: "Go Fish — you win", user: me, users: [ opponent ]).save!

# A finished Go Fish game you LOST -> modal shows "You lose".
create(:finished_game, :go_fish, :user_won, :has_participants,
       name: "Go Fish — you lose", user: opponent, users: [ me ]).save!

# A Rummy game where it's your turn and your hand is a single valid meld ->
# melding it empties your hand and wins the game, showing the end-of-game screen.
rummy = create(:started_game, :rummy, :users_turn, :has_participants,
               name: "Rummy — one play from winning", user: me, users: [ opponent ])
rummy.player_from_user(me).cards = [
  CardGame::Card.new("5", "Hearts"),
  CardGame::Card.new("5", "Spades"),
  CardGame::Card.new("5", "Clubs")
]
rummy.state.phase = "meld"
rummy.save!

puts "Seeding 1,000 players and their finished games for leaderboard load testing..."

# Bulk-inserted rather than built through FactoryBot: the leaderboard reads only users,
# participants, and games.started_at/finished_at/winner, so dealing 5,000 real hands would
# cost minutes for columns it never looks at. These games have a nil `state` — don't open one.
random = Random.new(20260728)
now = Time.current
timestamps = { created_at: now, updated_at: now }
digest = User.new(password: "password").password_digest

# Weighted so US dominates and the eq filter has one obviously-populous option to
# demonstrate against. Every id here must exist in config/countries.yml.
SEED_COUNTRIES = %w[US US US US CA GB MX JP PH ZA AU].freeze

user_rows = Array.new(1_000) do |n|
  { email_address: "player#{n + 1}@example.com", name: "Player #{n + 1}",
    country: SEED_COUNTRIES.sample(random: random),
    password_digest: digest, **timestamps }
end
user_ids = User.insert_all!(user_rows, returning: :id).rows.flatten

game_rows = Array.new(5_000) do |n|
  started_at = now - random.rand(1..90).days
  { name: "Load Test Game #{n + 1}", type: "GoFishGame", started_at: started_at,
    finished_at: started_at + random.rand(3..90).minutes, created_at: started_at, updated_at: now }
end
game_ids = Game.insert_all!(game_rows, returning: :id).rows.flatten

# Squaring a uniform draw pulls seats toward the front of the list, so the board gets a long
# tail: a few players with hundreds of games, many with one or two, and plenty with none.
seat = -> { user_ids[(random.rand**2 * user_ids.size).to_i] }

participant_rows = game_ids.flat_map do |game_id|
  host = seat.call
  guest = seat.call
  guest = seat.call while guest == host
  host_won = random.rand(2).zero?
  [ { game_id: game_id, user_id: host, host: true, winner: host_won, **timestamps },
    { game_id: game_id, user_id: guest, host: false, winner: !host_won, **timestamps } ]
end
Participant.insert_all!(participant_rows)

puts "Done. Sign in as me@example.com / password and open a game."
