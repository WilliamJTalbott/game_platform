RSpec.describe GoFish::Deck do
  let(:deck) { GoFish::Deck.new }
  let(:player) { GoFish::Player.new }

  it 'Should have 52 cards when created' do
    expect(deck.remaining).to eq 52
  end

  it 'should draw the top card' do
    card = deck.draw(player)
    expect(card).to be_a(GoFish::Card)
    expect(deck.remaining).to eq 51
  end

  it 'should draw several top cards' do
    card_array = deck.deal(player, 7)
    expect(card_array.size).to eq(7)
    expect(deck.remaining).to eq 45
  end

  describe 'shuffle' do
    it 'deck can be shuffled' do
      unshuffled_deck = GoFish::Deck.new
      expect(unshuffled_deck.cards).to eq deck.cards

      deck.shuffle
      expect(deck.cards).to_not eq unshuffled_deck.cards
    end
  end
end
