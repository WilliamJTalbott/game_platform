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

    it "preserves melds" do
      set_cards = [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
      game.melds = [ Rummy::Meld.new(kind: "set", owner: players.first.user_id, cards: set_cards) ]

      restored = described_class.load(game.as_json)

      expect(restored.melds.first).to have_attributes(kind: "set", owner: players.first.user_id, cards: set_cards)
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

      it "moves to the meld phase" do
        game.play_turn("draw_stock")
        expect(game.phase).to eq "meld"
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

      it "moves to the meld phase" do
        game.play_turn("draw_discard")
        expect(game.phase).to eq "meld"
      end
    end

    context "toggling a card's selection" do
      let(:card) { CardGame::Card.new("9", "Hearts") }

      before do
        game.phase = "meld"
        game.active_player.cards = [ card ]
      end

      it "adds the card to the active player's selection" do
        game.play_turn("toggle_select", card)
        expect(game.active_player.selected).to eq [ card ]
      end

      it "removes it again on a second toggle" do
        game.play_turn("toggle_select", card)
        game.play_turn("toggle_select", card)
        expect(game.active_player.selected).to eq []
      end

      it "does not advance the turn" do
        expect { game.play_turn("toggle_select", card) }.not_to change { game.turn_index }
        expect(game.phase).to eq "meld"
      end
    end

    context "melding" do
      let(:set_cards) do
        [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
      end

      before do
        game.phase = "meld"
        game.active_player.cards = set_cards + [ CardGame::Card.new("2", "Diamonds") ]
        game.active_player.selected = set_cards
      end

      it "creates a shared meld owned by the active player" do
        game.play_turn("meld")

        expect(game.melds.last).to have_attributes(
          kind: "set", owner: game.active_player.user_id, cards: set_cards
        )
      end

      it "removes the melded cards from the active player's hand" do
        game.play_turn("meld")
        expect(game.active_player.cards).to eq [ CardGame::Card.new("2", "Diamonds") ]
      end

      it "clears the selection" do
        game.play_turn("meld")
        expect(game.active_player.selected).to eq []
      end

      it "stays in the meld phase without advancing the turn" do
        game.play_turn("meld")
        expect(game.phase).to eq "meld"
        expect(game.turn_index).to eq 0
      end

      context "when the selection isn't a valid meld" do
        before { game.active_player.selected = [ set_cards.first ] }

        it "leaves the hand and melds untouched" do
          expect { game.play_turn("meld") }.not_to change { game.active_player.cards }
          expect(game.melds).to be_empty
        end
      end
    end

    context "laying off" do
      let(:existing_meld) do
        Rummy::Meld.new(
          kind: "run", owner: players.last.user_id,
          cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
        )
      end
      let(:layoff_card) { CardGame::Card.new("7", "Hearts") }

      before do
        game.phase = "meld"
        game.melds = [ existing_meld ]
        game.active_player.cards = [ layoff_card, CardGame::Card.new("2", "Diamonds") ]
        game.active_player.selected = [ layoff_card ]
      end

      it "extends the target meld with the selected card" do
        game.play_turn("lay_off", nil, 0)
        expect(game.melds.first.cards).to match_array(existing_meld.cards + [ layoff_card ])
      end

      it "removes the laid-off card from the active player's hand" do
        game.play_turn("lay_off", nil, 0)
        expect(game.active_player.cards).to eq [ CardGame::Card.new("2", "Diamonds") ]
      end

      it "clears the selection" do
        game.play_turn("lay_off", nil, 0)
        expect(game.active_player.selected).to eq []
      end

      it "stays in the meld phase without advancing the turn" do
        game.play_turn("lay_off", nil, 0)
        expect(game.phase).to eq "meld"
        expect(game.turn_index).to eq 0
      end

      context "when the selection does not legally extend the target meld" do
        before { game.active_player.selected = [ CardGame::Card.new("2", "Diamonds") ] }

        it "leaves the hand and meld untouched" do
          expect { game.play_turn("lay_off", nil, 0) }.not_to change { game.active_player.cards }
          expect(game.melds.first.cards).to eq existing_meld.cards
        end
      end
    end

    context "discarding" do
      let(:discarded_card) { CardGame::Card.new("A", "Spades") }

      before do
        game.phase = "meld"
        game.active_player.cards = [ discarded_card, CardGame::Card.new("2", "Hearts") ]
        game.active_player.selected = [ discarded_card ]
      end

      it "moves the selected card from the hand to the discard pile" do
        game.play_turn("discard")
        expect(game.discard.top).to eq discarded_card
      end

      it "removes the card from the hand" do
        discarder = game.active_player
        game.play_turn("discard")
        expect(discarder.cards).to eq [ CardGame::Card.new("2", "Hearts") ]
      end

      it "clears the selection" do
        discarder = game.active_player
        game.play_turn("discard")
        expect(discarder.selected).to eq []
      end

      it "advances the turn and returns to the draw phase" do
        expect { game.play_turn("discard") }
          .to change { game.turn_index }.from(0).to(1)
        expect(game.phase).to eq "draw"
      end

      context "when it empties the active player's hand" do
        before do
          game.active_player.cards = [ discarded_card ]
          game.active_player.selected = [ discarded_card ]
        end

        it "returns the active player as the winner" do
          winner = game.active_player
          expect(game.play_turn("discard")).to eq winner
        end
      end
    end
  end
end
