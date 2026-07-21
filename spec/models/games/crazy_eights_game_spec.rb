require 'rails_helper'

RSpec.describe CrazyEightsGame, type: :model do
  it_behaves_like "a platform game",
    factory: :crazy_eights,
    legal_turn: ->(game) do
      state = game.state
      playable = CrazyEights::Card.new("3", state.discard.active_card.suit)
      state.active_player.cards.unshift(playable)
      { card: playable.to_s }
    end,
    winning_turn: ->(game, winner) do
      state = game.state
      champion = state.players.find { |player| player.user_id == winner.id }
      state.turn_index = state.players.index(champion)
      winning_card = CrazyEights::Card.new("A", "Spades")
      champion.cards = [ winning_card ]
      state.discard.active_card = CrazyEights::Card.new("2", "Spades")
      { card: winning_card.to_s }
    end
end
