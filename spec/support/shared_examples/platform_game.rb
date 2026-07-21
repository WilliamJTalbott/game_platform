RSpec.shared_examples "a platform game" do |config|
  factory      = config.fetch(:factory)
  legal_turn   = config.fetch(:legal_turn)
  winning_turn = config.fetch(:winning_turn)

  let(:player_one) { create(:user) }
  let(:player_two) { create(:user) }
  let(:game) { create(:started_game, factory, :has_participants, users: [ player_one, player_two ]) }

  describe "the platform game contract" do
    context "when the game starts" do
      it "deals a hand to every player" do
        expect(game.state.players).to all(have_attributes(cards: be_present))
      end

      it "persists that the game has started" do
        expect(game.reload.started_at).to be_present
      end
    end

    context "when asked for its per-user objects" do
      it "builds a GamePresenter" do
        expect(game.presenter(player_one)).to be_a(GamePresenter)
      end

      it "supplies a form object for validating turns" do
        expect(game.form_class.ancestors).to include(ActiveModel::Model)
      end
    end

    context "when it is a player's turn" do
      it "recognizes the active player's user" do
        active = game.state.active_player
        active_user = game.users.find { |user| user.id == active.user_id }
        expect(game.user_turn?(active_user)).to be true
      end
    end

    context "when a legal turn is played" do
      it "changes the persisted game state" do
        expect { game.play_turn(**legal_turn.call(game)) }
          .to change { game.reload.state.as_json }
      end
    end

    context "when a winning turn is played" do
      before { game.play_turn(**winning_turn.call(game, player_one)) }

      it "marks the winning participant" do
        expect(game.participants.find_by(user: player_one)).to be_winner
      end

      it "stamps finished_at" do
        expect(game.reload.finished_at).to be_present
      end
    end
  end
end
