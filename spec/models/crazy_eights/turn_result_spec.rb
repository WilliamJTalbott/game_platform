RSpec.describe CrazyEights::TurnResult do
  let(:players) do
    [
      CrazyEights::Player.new(nil, "Bob"),
      CrazyEights::Player.new(nil, "Tom")
    ]
  end
  let(:current_player) { players.first }
  let(:card) { CrazyEights::Card.new("8", "Hearts") }
  let(:turn_result) { described_class.new(players, current_player, card) }

  it "tells every player which card was played" do
    turn_result

    expect(players).to all(satisfy do |player|
      player.messages.any? { |message| message.text == "Bob played 8♥." }
    end)
  end

  it "tells every player when the active suit changes" do
    turn_result.suit_changed("Clubs")

    expect(players).to all(satisfy do |player|
      player.messages.any? { |message| message.text == "The active suit is now Clubs." }
    end)
  end

  it "tells every player who won" do
    turn_result.winner

    expect(players).to all(satisfy do |player|
      player.messages.any? { |message| message.text == "Bob wins!" }
    end)
  end
end
