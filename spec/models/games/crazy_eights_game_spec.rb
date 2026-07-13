require 'rails_helper'

RSpec.describe CrazyEightsGame, type: :model do
  describe "#play_turn" do
    let(:winner) { create(:user) }
    let(:opponent) { create(:user) }
    let(:game) { create(:started_game, :crazy_eights, :has_participants, users: [winner, opponent]) }
    let(:winning_player) { game.player_from_user(winner) }
    let(:winning_card) { CrazyEights::Card.new("A", "Spades") }

    before do
      game.state.turn_index = game.state.players.index(winning_player)
      winning_player.cards = [winning_card]
      game.state.discard.active_card = CrazyEights::Card.new("2", "Spades")
      game.save!
    end

    it "finishes the game and records the winner" do
      game.play_turn(card: winning_card.to_s)
      expect(game.reload.finished_at).to be_present
      expect(game.participants.find_by(user: winner)).to be_winner
    end
  end
end
