include FactoryBot::Syntax::Methods

puts "Cleaning the database..."
User.destroy_all
Game.destroy_all

puts "Seeding database with FactoryBot..."

create(:user)
create(:game, :go_fish, :finished, name: "Seed Game")