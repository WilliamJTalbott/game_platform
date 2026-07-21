require 'rails_helper'

RSpec.describe GoFishGame, type: :model do
  it_behaves_like "a platform game",
    factory: :go_fish,
    legal_turn: ->(game) do
      state = game.state
      opponent = (state.players - [ state.active_player ]).first
      { player_name: opponent.name, rank: state.active_player.cards.first.rank }
    end,
    winning_turn: ->(game, winner) do
      state = game.state
      state.deck.cards = []
      state.players.each { |player| player.cards = [] }
      champion = state.players.find { |player| player.user_id == winner.id }
      champion.books = [ GoFish::Book.new("A") ]
      state.turn_index = state.players.index(champion)
      { player_name: (state.players - [ champion ]).first.name, rank: "A" }
    end
end
