require 'rails_helper'

RSpec.describe Rummy::Game do
  let(:players) { Array.new(2) { Rummy::Player.new } }
  let!(:game) { described_class.new(players) }

  describe "#deal" do
    it "deals a ten-card hand to each player" do
      game.deal
      expect(game.players).to all have_attributes(cards: have_attributes(size: 10))
    end

    it "flips one card from the deck onto the discard" do
      game.deal
      expect(game.discard.top).to be_a CardGame::Card
    end

    it "removes the dealt and flipped cards from the deck" do
      game.deal
      expect(game.deck.remaining).to eq 52 - (10 * players.size) - 1
    end
  end

  describe "#as_json" do
    it "transforms it into json" do
      game.deal
      json = game.as_json
      expect(json["players"].count).to eq players.size
      expect(json["discard"]["cards"].size).to eq 1
    end
  end

  describe "#load" do
    it "preserves round-trip state" do
      game.deal
      restored = described_class.load(game.as_json)

      expect(restored.players).to all be_a Rummy::Player
      expect(restored.discard).to be_a Rummy::Discard
      expect(restored.discard.top).to eq game.discard.top
    end
  end

  describe "#play_turn" do
    let(:top_of_deck) { CardGame::Card.new("K", "Diamonds") }
    let(:top_of_discard) { CardGame::Card.new("7", "Clubs") }

    before do
      game.deck.cards = [ top_of_deck ]
      game.discard.cards = [ top_of_discard ]
      players.each { |player| player.cards = [] }
    end

    context "drawing from the stock" do
      it "moves the top card of the deck into the active player's hand" do
        game.play_turn("draw_stock")
        expect(game.active_player.cards).to eq [ top_of_deck ]
      end

      it "moves to the discard phase" do
        game.play_turn("draw_stock")
        expect(game.phase).to eq "discard"
      end

      context "when the stock is depleted" do
        before { game.deck.cards = [] }

        it "recycles the discard (minus its top card) into the stock first" do
          game.discard.cards = [ CardGame::Card.new("2", "Hearts"), top_of_discard ]
          game.play_turn("draw_stock")

          expect(game.active_player.cards).to eq [ CardGame::Card.new("2", "Hearts") ]
          expect(game.discard.cards).to eq [ top_of_discard ]
        end
      end
    end

    context "drawing from the discard" do
      it "moves the top of the discard into the active player's hand" do
        game.play_turn("draw_discard")
        expect(game.active_player.cards).to eq [ top_of_discard ]
      end

      it "removes the card from the discard pile" do
        game.play_turn("draw_discard")
        expect(game.discard.top).to be_nil
      end

      it "moves to the discard phase" do
        game.play_turn("draw_discard")
        expect(game.phase).to eq "discard"
      end
    end

    context "discarding" do
      let(:discarded_card) { CardGame::Card.new("A", "Spades") }

      before do
        game.phase = "discard"
        game.active_player.cards = [ discarded_card, CardGame::Card.new("2", "Hearts") ]
      end

      it "moves the card from the hand to the discard pile" do
        game.play_turn("discard", discarded_card)
        expect(game.discard.top).to eq discarded_card
      end

      it "advances the turn and returns to the draw phase" do
        expect { game.play_turn("discard", discarded_card) }
          .to change { game.turn_index }.from(0).to(1)
        expect(game.phase).to eq "draw"
      end

      context "when it empties the active player's hand" do
        before { game.active_player.cards = [ discarded_card ] }

        it "returns the active player as the winner" do
          winner = game.active_player
          expect(game.play_turn("discard", discarded_card)).to eq winner
        end
      end
    end
  end
end
