RSpec.describe GoFish::Card do
  it 'has rank and Suit' do
    card = GoFish::Card.new('A', 'Clubs')
    expect(card.rank).to eq 'A'
    expect(card.suit).to eq 'Clubs'
  end

  it 'card of the same rank and suit are equal' do
    card1 = GoFish::Card.new('A', 'Clubs')
    card2 = GoFish::Card.new('10', 'Clubs')
    card3 = GoFish::Card.new('A', 'Clubs')

    expect(card1).to eq card3
    expect(card1).to_not eq card2
  end

  it 'should allow valid ranks' do
    expect do
      GoFish::Card.new('15', 'Clubs')
    end.to raise_error GoFish::Card::InvalidRank
  end

  it 'should allow valid suits' do
    expect do
      GoFish::Card.new('A', 'Minecraft')
    end.to raise_error GoFish::Card::InvalidSuit
  end
end
