require 'rails_helper'

RSpec.describe GoFish do

  context "When dealing cards" do

    let!(:original) { described_class.new }
    let(:json) { described_class.dump(original) }
    let(:restored) { described_class.load(json) }

    it "Players are dealt cards" do
      
    end

    it "Player data unchanged" do
      original.deal!
      expect(restored.players).to eq original.players
    end
  end
end