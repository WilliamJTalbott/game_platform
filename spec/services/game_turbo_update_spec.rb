require 'rails_helper'

RSpec.describe GameTurboUpdate do
  let(:user) { create(:user) }
  let(:opponent) { create(:user) }

  describe "#broadcast" do
    let(:game_frame) { ActionView::RecordIdentifier.dom_id(game) }
    before { allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to) }

    context "when the game is in progress" do
      let(:game) { create(:started_game, :go_fish, :has_participants, users: [ user, opponent ]) }

      it "replaces the game frame on the user's stream" do
        described_class.broadcast(game, user)
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
          .with(game, user, hash_including(target: game_frame))
      end

      it "does not broadcast the end-of-game modal" do
        described_class.broadcast(game, user)
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).once
      end
    end

    context "when the game is finished" do
      let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: user) }
      before { game.update!(finished_at: Time.current) }

      it "replaces the game frame and the end-of-game modal" do
        described_class.broadcast(game, user)
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
          .with(game, user, hash_including(target: game_frame))
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
          .with(game, user, hash_including(target: "end_of_game_modal"))
      end
    end
  end
end
