
require 'rspec'

RSpec.describe CleanGamesJob do
  context 'when preformed' do
    let! (:game) { create(:old_game) }

    it "sets old game's deleted at" do
      described_class.perform_now
      expect(game.reload.deleted_at).to be_present
    end
  end
end
