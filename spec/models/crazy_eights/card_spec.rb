require "rails_helper"

RSpec.describe CrazyEights::Card do
  describe ".from_s" do
    it "parses a ten" do
      card = described_class.from_s("10♦")

      expect(card).to eq described_class.new("10", "Diamonds")
    end
  end
end
