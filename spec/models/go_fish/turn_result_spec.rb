require 'rails_helper'

RSpec.describe GoFish::TurnResult do
  let!(:players) { [ GoFish::Player.new(nil, "Bob"), GoFish::Player.new(nil, "Tom"), GoFish::Player.new(nil, "Jerry") ] }
  let!(:current_player) { players.first }
  let!(:target_player) { players[1] }
  let!(:viewing_player) { players.last }
  let!(:turn_result) { GoFish::TurnResult.new(players, current_player, target_player, "A") }

  describe "#output" do
    it "has all the info" do
      action_message = viewing_player.messages.first
      expect(action_message.text).to include("Bob", "Tom", "A")
    end

    context "when a player askes and gets cards" do
      before do
        target_player.cards = [ CardGame::Card.new("A"), CardGame::Card.new("A") ]
        turn_result.got_cards(2)
      end
      it "lists the amount of cards recieved" do
        got_message = viewing_player.messages[1]
        expect(got_message.text).to include("got 2 A's")
      end
    end
  end
end
