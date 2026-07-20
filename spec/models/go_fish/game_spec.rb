RSpec.describe GoFish::Game do
  let(:num_players) { 5 }
  let!(:players) { Array.new(num_players) { GoFish::Player.new } }
  let!(:game) { described_class.new(players) }

  let!(:target_player) { game.players[1] }
  let(:active_player) { game.active_player }

  let(:unshuffled_cards) {
    [
      GoFish::Card.new("10", "Diamonds"),
      GoFish::Card.new("J", "Diamonds"),
      GoFish::Card.new("Q", "Diamonds"),
      GoFish::Card.new("K", "Diamonds"),
      GoFish::Card.new("A", "Diamonds")
    ]
  }

  describe "#as_json" do
    let(:json) { game.as_json }
    it "transforms it into json" do
      expect(json["players"].count).to eq num_players
    end
  end

  describe "#load" do
    let(:json) { game.as_json }
    let(:restored) { described_class.load(json) }
    it "preserves round-trip state" do
      expect(restored.players).to all be_a GoFish::Player
    end
  end

    describe "#deal" do
      context "when players are passed in" do
        it "shuffles and deals the deck" do
          game.deal
          expect(active_player.cards).to_not eq(unshuffled_cards)
          expect(active_player.cards.size).to eq(5)
        end
      end
    end

  describe "#run_turn" do
    context "active player has 1 card" do
      before { active_player.cards = [ GoFish::Card.new("A") ] }

      context "and target has 0 matching cards" do
        context "deck has no cards" do
          it "player receives no new cards" do
            before_cards = active_player.cards.dup
            game.deck.cards = []
            game.play_turn(target_player, "A")
            expect(active_player.cards).to eq before_cards
          end
        end

        context "deck has at least 1 card" do
          context "when player fishes same rank"
            it "keeps active_player turn" do
              deck_top_card = game.deck.cards.last.dup
              game.play_turn(target_player, "A")
              expect(active_player.cards).to include(deck_top_card)
            end
          end

          context "when player fishes different rank" do
            it "ends active_player turn" do
              deck_top_card = game.deck.cards.last.dup
              game.play_turn(target_player, "A")
              expect(active_player.cards).to include(deck_top_card)
            end
          end
        end

      context "and target has 1 matching card" do
        it "gives targets 'card' to player " do
          card = GoFish::Card.new("A")
          target_player.cards = [ card ]
          game.play_turn(target_player, "A")
          expect(active_player.cards).to include(card)
        end
      end

      context "and target has 2 matching cards" do
        it "gives target 'cards' to player" do
          cards = [ GoFish::Card.new("A"), GoFish::Card.new("A") ]
          target_player.cards = cards
          game.play_turn(target_player, "A")
          expect(active_player.cards).to include(*cards)
        end
      end

      context "and target has 3 matching cards" do
        it "active player creates a book" do
          cards = [ GoFish::Card.new("A"), GoFish::Card.new("A"), GoFish::Card.new("A") ]
          book = GoFish::Book.new("A")
          target_player.cards = cards
          game.play_turn(target_player, "A")
          expect(active_player.books).to include(book)
        end
      end
    end
  end

  describe "End States" do
    let!(:player1) { game.players[0] }
    let!(:player2) { game.players[1] }
    let!(:player3) { game.players[2] }
    before(:each) { game.deck.cards = [] }

    context "when players are all out of cards" do
      before do
        player1.name = "Bobert"
        game.players.each do |player|
          player.cards = []
        end
      end

      context "when one player has more books" do
        before do
          player1.books = [ GoFish::Book.new("2"), GoFish::Book.new("10") ]
          player2.books = [ GoFish::Book.new("A") ]
        end
        it "returns winner and adds message with winner" do
          winner = game.play_turn(player2, "A")
          message = player2.messages[2]
          expect(message.text).to include("Bobert wins")
          expect(winner).to be player1
        end
      end

      context "when players have a tied number of books" do
        before do
          player1.books = [ GoFish::Book.new("5"), GoFish::Book.new("10") ]
          player2.books = [ GoFish::Book.new("3"), GoFish::Book.new("2") ]
          player3.books = [ GoFish::Book.new("A") ]
        end
        it "message contains tied player with highest book" do
          game.play_turn(player2, "A")
          message = player2.messages[2]
          expect(message.text).to include("Bobert wins")
        end
      end
    end

    context "when a player is out of cards" do
      before do
        player1.cards = [ GoFish::Card.new("3") ]
        player2.cards = []
        player3.cards = [ GoFish::Card.new("2") ]
      end
      it "skips their turn" do
        game.play_turn(player2, "3")
        expect(game.active_player).to eq player3
      end
    end

    context "when a player runs out of cards mid turn and no cards in deck" do
      before do
        player1.cards = [ GoFish::Card.new("3"), GoFish::Card.new("3"), GoFish::Card.new("3") ]
        player2.cards = [ GoFish::Card.new("3"), GoFish::Card.new("5") ]
      end
      it "skips their turn" do
        game.play_turn(player2, "3")
        expect(game.active_player).to eq player2
      end
    end
  end
end
