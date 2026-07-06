
Card = GoFish::Card
Player = GoFish::Player

RSpec.describe GoFish::Game do
  let(:num_players) { 5 }
  let!(:players) { Array.new(num_players) { Player.new } }
  let!(:game) { described_class.new(players) }
  let(:player) { players.first }

  describe "#dump" do
    let(:json) { described_class.dump(game) }
    it "transforms it into json" do
      expect(json[:players].count).to eq num_players
    end
  end

  describe "#load" do
    let(:json) { described_class.dump(game) }
    let(:restored) { described_class.load(json) }
    it "preserves round-trip state" do
      expect(restored.players).to all be_a Player
    end
  end

  describe '#start' do
    let(:unshuffled_hand) { [
      Card.new("10", "Diamonds"),
      Card.new("J", "Diamonds"),
      Card.new("Q", "Diamonds"),
      Card.new("K", "Diamonds"),
      Card.new("A", "Diamonds")
    ] }
    it "shuffles and deals the deck" do
      game.start
      expect(player.cards).to_not eq(unshuffled_hand)
      expect(player.cards.size).to eq(5)
    end
  end

end