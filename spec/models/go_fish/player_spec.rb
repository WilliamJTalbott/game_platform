RSpec.describe GoFish::Player do
  let(:player) {GoFish::Player.new("Bob")}

  describe "#take" do
    it "removes and returns all hand cards with same rank" do
      cards = [GoFish::Card.new("K"), GoFish::Card.new("K"), GoFish::Card.new("A")]
      player.cards = cards.dup

      expect(player.take("K")).to eq cards.first(2)
      expect(player.cards).to eq cards.last(1)
    end
  end

  describe "#receive" do

    context "player hand no cards" do
      it "it adds a number of cards" do
        cards = [GoFish::Card.new("A", "Hearts"), GoFish::Card.new("K", "Clubs")]
        player.receive(cards.dup)
        expect(player.cards).to include(*cards)
      end
    end

    context "player hand has 3 identical rank cards" do
      it "removes them and adds a book" do
        player.cards = [GoFish::Card.new("A", "Hearts"), GoFish::Card.new("A", "Clubs"), GoFish::Card.new("A", "Spades")]
        player.receive([GoFish::Card.new("A", "Diamonds")])
        expect(player.cards).to be_empty
        expect(player.books).to_not be_empty
      end
    end
  end

end
