module Rummy
  class Meld
    include Serializable

    RANK_VALUES = {
      "A" => 1, "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7,
      "8" => 8, "9" => 9, "10" => 10, "J" => 11, "Q" => 12, "K" => 13
    }.freeze

    attr_reader :kind, :owner, :cards

    def initialize(kind:, owner:, cards:)
      @kind = kind
      @owner = owner
      @cards = cards
    end

    serializes :kind, :owner, cards: [ CardGame::Card ]

    def self.build(cards:, owner:)
      kind = kind_for(cards)
      return nil unless kind

      new(kind: kind, owner: owner, cards: cards)
    end

    def self.valid?(cards) = kind_for(cards).present?

    class << self
      private

      def kind_for(cards)
        return "set" if set?(cards)
        "run" if run?(cards)
      end

      def set?(cards)
        cards.size >= 3 && cards.map(&:rank).uniq.size == 1 && cards.map(&:suit).uniq.size == cards.size
      end

      def run?(cards)
        cards.size >= 3 && cards.map(&:suit).uniq.size == 1 && consecutive_ranks?(cards)
      end

      def consecutive_ranks?(cards)
        values = cards.map { |card| RANK_VALUES.fetch(card.rank) }.sort
        values.uniq.size == values.size && values.last - values.first == values.size - 1
      end
    end
  end
end
