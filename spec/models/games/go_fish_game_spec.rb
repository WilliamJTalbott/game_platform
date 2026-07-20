require 'rails_helper'

RSpec.describe GoFishGame, type: :model do

  let(:winner) { create :user }
  let(:opponent) { create :user }
  let(:game) { create(:started_game, :go_fish, :has_participants, users: [winner, opponent]) }

  def play_winning_turn(game)
    state = game.state
    state.deck.cards = []
    state.players.each { |player| player.cards = [] }
    state.players.first.books = [ GoFish::Book.new("A") ]
    game.play_turn(player_name: state.players.second.name, rank: "A")
  end

  describe "#play_turn ending the game" do

    context "when winning turn is played" do
      before { play_winning_turn(game) }

      it "marks the winning participant" do
        expect(game.participants.find_by(user: winner)).to be_winner
      end

      it "stamps finished_at when the game ends" do
        expect(game.reload.finished_at).to_not be_nil
      end

      it "reports status 'finished'" do
        expect(game.reload.status).to eq 'finished'
      end
    end
  end
end
