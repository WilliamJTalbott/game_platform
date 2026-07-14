RSpec.describe GoFish::TurnResult do
  let!(:players) {[GoFish::Player.new(nil, "Bob"), GoFish::Player.new(nil, "Tom"), GoFish::Player.new(nil, "Jerry")]}
  let!(:current_player) { players.first }
  let!(:target_player) { players[1] }
  let!(:viewing_player) { players.last }
  let!(:turn_result) { GoFish::TurnResult.new(players, current_player, target_player, "A") }

  describe "#output" do
    it "has all the info" do
      action_message = viewing_player.messages.first
      expect(action_message.text).to include("Bob", "Tom", "A")
    end

    xcontext "when a book on a player is created" do
      before do
        current_player.cards = [GoFish::Card.new("A"), GoFish::Card.new("A"), GoFish::Card.new("A")]
        current_player.receive([GoFish::Card.new("A")])
      end

      it "lists the book type created" do
        expect(current_player.book_count).to eq 1
        expect(turn_result.output).to include("a book of A's")
      end
    end

    context "when a player askes and gets cards" do
      before do
        target_player.cards = [GoFish::Card.new("A"), GoFish::Card.new("A")]
        turn_result.got_cards(2)
      end
      it "lists the amount of cards recieved" do
        got_message = viewing_player.messages[1]
        expect(got_message.text).to include("got 2 A's")
      end
    end
  end

end
