require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:game) { create(:game, :many_participants) }

  context "#status" do
    let(:unstarted_game) { create(:game) }
    it "returns 'waiting' if game hasn't started" do
      expect(unstarted_game.status).to eq 'waiting'
    end

    it "returns 'started' if game has started" do
      game.start
      expect(game.status).to eq 'started'
    end

    it "returns 'finished' if game has ended" do
      game.start
      game.finish
      expect(game.status).to eq 'finished'
    end
  end

  context "#max_players" do
    it "reads the subclass's MAX_PLAYERS constant" do
      expect(create(:game, :go_fish).max_players).to eq GoFishGame::MAX_PLAYERS
    end
  end

  context "#full?" do
    let(:game) { create(:game, :crazy_eights) }

    it "is false below the player cap" do
      expect(game.full?).to be false
    end

    it "is true once participants reach the cap" do
      create_list(:participant, CrazyEightsGame::MAX_PLAYERS, game: game)
      expect(game.reload.full?).to be true
    end
  end

  context "#waiting" do
    it "includes an unstarted, undeleted game" do
      expect(Game.waiting).to include create(:game)
    end

    it "excludes started and soft-deleted games" do
      started = create(:started_game, :many_participants)
      deleted = create(:deleted_game)
      expect(Game.waiting).to_not include(started, deleted)
    end
  end

  context "#active" do
    it "includes a started, unfinished game" do
      expect(Game.active).to include create(:started_game, :many_participants)
    end

    it "excludes waiting and finished games" do
      waiting = create(:game)
      finished = create(:finished_game, :many_participants).tap { |g| g.update!(finished_at: Time.current) }
      expect(Game.active).to_not include(waiting, finished)
    end
  end

  context "#can_start?" do
    let(:empty_game) { create(:game) }

    it "returns true with 2+ participants" do
      expect(game.can_start?).to be true
    end

    it "returns false with no participants" do
      expect(empty_game.can_start?).to be false
    end
  end

  context "#playable" do
    it "returns every registered game subclass" do
      expect(Game.playable).to match_array([ GoFishGame, CrazyEightsGame, RummyGame ])
    end
  end

  context "#from_type" do
    it "resolves a registered type name to its class" do
      expect(Game.from_type("GoFishGame")).to eq GoFishGame
    end

    it "returns nil for an unregistered type name" do
      expect(Game.from_type("NotAGame")).to be_nil
    end
  end

  context "#finished" do
    it "includes a game with both started_at and finished_at present" do
      finished_game = create(:finished_game, :many_participants).tap { |game| game.update!(finished_at: Time.current) }
      expect(Game.finished).to include finished_game
    end

    it "excludes a waiting game" do
      waiting_game = create(:game)
      expect(Game.finished).to_not include waiting_game
    end

    it "excludes a started-but-not-finished game" do
      started_game = create(:started_game, :many_participants)
      expect(Game.finished).to_not include started_game
    end

    it "includes a finished game that has since been soft-deleted" do
      finished_game = create(:finished_game, :many_participants).tap { |game| game.update!(finished_at: Time.current, deleted_at: Time.current) }
      expect(Game.finished).to include finished_game
    end

    it "orders most-recently-finished first" do
      older = create(:finished_game, :many_participants).tap { |game| game.update!(finished_at: 2.days.ago) }
      newer = create(:finished_game, :many_participants).tap { |game| game.update!(finished_at: 1.day.ago) }
      expect(Game.finished).to eq [ newer, older ]
    end
  end
end
