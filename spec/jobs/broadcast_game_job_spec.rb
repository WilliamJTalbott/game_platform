require 'rails_helper'

RSpec.describe BroadcastGameJob, type: :job do
  let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: create(:user)) }

  describe "broadcasting a game" do
    context "when the job runs" do
      it "broadcasts once per participant" do
        expect(GameTurboUpdate).to receive(:broadcast).exactly(game.users.count).times
        described_class.perform_now(game)
      end

      it "targets each participant's own per-user stream" do
        game.users.each do |participant_user|
          expect(GameTurboUpdate).to receive(:broadcast).with(game, participant_user)
        end
        described_class.perform_now(game)
      end
    end
  end
end
