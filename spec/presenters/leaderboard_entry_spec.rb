require 'rails_helper'

RSpec.describe LeaderboardEntry, type: :presenter do
  def entry(play_seconds: 0, win_percentage: 0)
    described_class.new(rank: 1, name: "Ana", games_played: 1, games_won: 1,
      win_percentage: win_percentage, play_seconds: play_seconds, you: false)
  end

  describe "#play_time" do
    context "given a total of an hour or more" do
      it "formats as hours and zero-padded minutes" do
        expect(entry(play_seconds: 14.hours.to_i + 7.minutes.to_i).play_time).to eq "14h 07m"
      end
    end

    context "given a total under an hour" do
      it "formats as zero-padded minutes and seconds" do
        expect(entry(play_seconds: 7.minutes.to_i + 12.seconds.to_i).play_time).to eq "07m 12s"
      end
    end

    context "given zero" do
      it "formats as 0m" do
        expect(entry(play_seconds: 0).play_time).to eq "0m"
      end
    end
  end

  describe "#win_percentage" do
    it "formats with one decimal place" do
      expect(entry(win_percentage: 62.5).win_percentage).to eq "62.5%"
    end
  end

  describe "#you?" do
    it "reflects the value it was built with" do
      you_entry = described_class.new(rank: 1, name: "Ana", games_played: 1, games_won: 1,
        win_percentage: 0, play_seconds: 0, you: true)
      expect(you_entry.you?).to be true
    end
  end

  describe "#flag" do
    it "returns the flag emoji for a known country" do
      entry = described_class.new(rank: 1, name: "Ana", games_played: 1, games_won: 1,
        win_percentage: 0, play_seconds: 0, you: false, country: "US")
      expect(entry.flag).to eq "🇺🇸"
    end

    it "returns nil for a blank country" do
      expect(entry.flag).to be_nil
    end

    it "returns nil for an unrecognized country id" do
      entry = described_class.new(rank: 1, name: "Ana", games_played: 1, games_won: 1,
        win_percentage: 0, play_seconds: 0, you: false, country: "ZZ")
      expect(entry.flag).to be_nil
    end
  end
end
