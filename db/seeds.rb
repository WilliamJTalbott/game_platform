include FactoryBot::Syntax::Methods

puts "Cleaning the database..."
User.destroy_all
Game.destroy_all

puts "Seeding database with FactoryBot..."

create(:game, :go_fish, :has_winner, name: "Seed Game")