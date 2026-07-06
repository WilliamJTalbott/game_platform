include FactoryBot::Syntax::Methods

puts "Cleaning the database..."
User.destroy_all
Game.destroy_all

puts "Seeding database with FactoryBot..."

GAMES_LOST = 8
GAMES_WON = 5

# Use 'person1@example.com' and 'password' to login

users = create_list(:user, 5)
GAMES_LOST.times { create(:game, :go_fish, :lost, users: users) }
GAMES_WON.times { create(:game, :go_fish, :won, users: users) }