

RSpec.describe CrazyEights::Game do

  let!(:players) { Array.new(num_players) { CrazyEights::Player.new } }
  let!(:game) { described_class.new(players) }

  let(:num_players) { 5 }
  let(:active_player) { game.active_player }

  let(:unshuffled_cards) {
    [
      Card.new("10", "Diamonds"),
      Card.new("J", "Diamonds"),
      Card.new("Q", "Diamonds"),
      Card.new("K", "Diamonds"),
      Card.new("A", "Diamonds")
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

    before do
      game.discard.place(Card.new("8", "Spades"), "Hearts")
    end

    it "preserves round-trip state" do
      expect(restored.players).to all be_a CrazyEights::Player
      expect(restored.discard.cards).to eq game.discard.cards
      expect(restored.discard.active_card).to eq game.discard.active_card
    end
  end

  describe "#deal" do
    context "when players are passed in" do
      it "shuffles and deals the deck" do
        game.deal
        expect(active_player.cards).to_not eq(unshuffled_cards)
        expect(active_player.cards.size).to eq(described_class::SMALL_HAND)
      end
    end
  end

  describe "#play_turn" do

    context "player plays a valid card" do
      let(:card) { Card.new("A", "Spades") }
      before do
        active_player.cards << card
        game.discard.active_card = Card.new("2", "Spades")
      end

      it "Adds card to active card" do
        game.play_turn(card)
        expect(game.discard.active_card).to eq card
      end

      it "removes an equivalent submitted card from the player's hand" do
        submitted_card = Card.new(card.rank, card.suit)

        game.play_turn(submitted_card)

        expect(active_player.cards).not_to include(card)
      end

      it "adds a played-card message for every player" do
        game.play_turn(card)

        expect(game.players).to all(satisfy do |player|
          player.messages.any? { |message| message.text == "unset played A♠." }
        end)
      end
    end

    context "player plays a wild and specifies suit" do
      let(:card) { Card.new("8", "Spades") }
      let(:suit) { "Clubs" }
      let(:outcome) { Card.new(card.rank, suit) }

      before do
        active_player.cards << card
        game.discard.active_card = Card.new("2", "Hearts")
      end

      it "Adds card to active card" do
        game.play_turn(card, suit)
        expect(game.discard.active_card).to eq outcome
      end

      it "adds an active-suit alert for every player" do
        game.play_turn(card, suit)

        expect(game.players).to all(satisfy do |player|
          player.messages.any? { |message| message.text == "The active suit is now Clubs." }
        end)
      end
    end


    context "turn without winner" do
      let(:card) { Card.new("A", "Spades") }
      let!(:next_player) { game.players[game.turn_index + 1] }

      before do
        game.deal
        game.active_player.cards << card
        game.discard.active_card = card
      end

      it "switches turn at end of round" do
        game.play_turn(card)
        expect(game.active_player).to eq next_player
      end

      context "new user has playable card" do
        before do
          next_player.cards = [card]
        end

        it "switches turn at end of round" do
          game.play_turn(card)
          expect(next_player.cards.size).to eq 1
        end
      end

      context "new user does not have playable card" do
        let(:unplayable_card) { Card.new("6", "Hearts") }

        before do
          next_player.cards = [ unplayable_card ]
        end

        it "deals until playable card" do
          game.play_turn(card)
          expect(next_player.cards.size).to be > 1
        end
      end

    end

    context "player runs out of cards" do
      let(:card) { Card.new("A", "Spades") }

      before do
        game.players.map { |player| player.cards = [] }
        game.discard.active_card = card
        game.active_player.cards = [ card ]
      end
      
      it "returns them as the winner" do
        expect(game.play_turn(card)).to eq active_player
      end

      it "adds a winner alert for every player" do
        game.play_turn(card)

        expect(game.players).to all(satisfy do |player|
          player.messages.any? { |message| message.text == "unset wins!" }
        end)
      end
    end

    context "the deck is empty" do
      let(:card) { Card.new("A", "Spades") }
      let(:recycled_card) { Card.new("A", "Hearts") }
      let(:next_player) { game.players[1] }

      before do
        active_player.cards = [card, Card.new("3", "Clubs")]
        next_player.cards = [Card.new("6", "Hearts")]
        game.deck.cards = []
        game.discard.cards = [recycled_card]
        game.discard.active_card = Card.new("2", "Spades")
      end

      it "recycles the discard pile so the next player can draw" do
        game.play_turn(card)

        expect(next_player.cards).to include(recycled_card)
      end
    end


  end
end
