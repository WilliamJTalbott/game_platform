# Temporary preview for the Rummy static mockup (docs/mockups/rummy-final.html).
# Delete this controller + its route once Rummy has a real Game/Presenter to render from.
class RummyPreviewsController < ApplicationController
  Card = Struct.new(:rank, :suit, keyword_init: true)
  Opponent = Struct.new(:name, :hand_count, :meld_count, :turn, keyword_init: true)
  Meld = Struct.new(:kind, :owner, :cards, :selected, keyword_init: true)
  HandCard = Struct.new(:card, :selected, keyword_init: true)

  def show
    @opponents = [
      Opponent.new(name: "Alice", hand_count: 7, meld_count: 2, turn: false),
      Opponent.new(name: "Carol", hand_count: 6, meld_count: 3, turn: true),
      Opponent.new(name: "Bob", hand_count: 9, meld_count: 1, turn: false)
    ]

    @discard_top = Card.new(rank: "7", suit: "Clubs")

    @melds = [
      Meld.new(kind: "Run ♥", owner: "you", selected: false, cards: [
        Card.new(rank: "4", suit: "Hearts"), Card.new(rank: "5", suit: "Hearts"), Card.new(rank: "6", suit: "Hearts")
      ]),
      Meld.new(kind: "Set 9", owner: "Alice", selected: true, cards: [
        Card.new(rank: "9", suit: "Spades"), Card.new(rank: "9", suit: "Diamonds"), Card.new(rank: "9", suit: "Clubs")
      ]),
      Meld.new(kind: "Run ♠", owner: "Carol", selected: false, cards: [
        Card.new(rank: "J", suit: "Spades"), Card.new(rank: "Q", suit: "Spades"), Card.new(rank: "K", suit: "Spades")
      ]),
      Meld.new(kind: "Set 2", owner: "Bob", selected: false, cards: [
        Card.new(rank: "2", suit: "Hearts"), Card.new(rank: "2", suit: "Spades"), Card.new(rank: "2", suit: "Clubs")
      ]),
      Meld.new(kind: "Run ♦", owner: "Carol", selected: false, cards: [
        Card.new(rank: "7", suit: "Diamonds"), Card.new(rank: "8", suit: "Diamonds"),
        Card.new(rank: "9", suit: "Diamonds"), Card.new(rank: "10", suit: "Diamonds")
      ])
    ]

    selected_hand_cards = [ "3-Diamonds", "4-Diamonds", "5-Diamonds" ]
    @hand_cards = [
      Card.new(rank: "A", suit: "Diamonds"), Card.new(rank: "3", suit: "Diamonds"),
      Card.new(rank: "4", suit: "Diamonds"), Card.new(rank: "5", suit: "Diamonds"),
      Card.new(rank: "8", suit: "Clubs"), Card.new(rank: "10", suit: "Hearts"),
      Card.new(rank: "Q", suit: "Diamonds"), Card.new(rank: "K", suit: "Hearts")
    ].map { |card| HandCard.new(card: card, selected: selected_hand_cards.include?("#{card.rank}-#{card.suit}")) }
  end
end
