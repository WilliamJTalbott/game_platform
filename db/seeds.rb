include FactoryBot::Syntax::Methods

puts "Cleaning the database..."
User.destroy_all
Game.destroy_all

puts "Seeding database with FactoryBot..."

# Log in as 'me@example.com' / 'password' to view the end-of-game screens.
me = create(:user, email_address: "me@example.com")
opponent = create(:user, email_address: "opponent@example.com")

# A finished Go Fish game you WON -> modal shows "You win".
create(:finished_game, :go_fish, :user_won, :has_participants,
       name: "Go Fish — you win", user: me, users: [ opponent ]).save!

# A finished Go Fish game you LOST -> modal shows "You lose".
create(:finished_game, :go_fish, :user_won, :has_participants,
       name: "Go Fish — you lose", user: opponent, users: [ me ]).save!

puts "Done. Sign in as me@example.com / password and open a game."
