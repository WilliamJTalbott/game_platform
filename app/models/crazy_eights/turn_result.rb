module CrazyEights
  class TurnResult
    attr_reader :players, :current_player, :card

    def initialize(players, current_player, card)
      @players = players
      @current_player = current_player
      @card = card

      card_played
    end

    def suit_changed(suit)
      broadcast_alert("The active suit is now #{suit}.")
    end

    def winner
      broadcast_alert("#{current_player.name} wins!")
    end

    private

    def card_played
      broadcast_action("#{current_player.name} played #{card}.")
    end

    def broadcast_action(text)
      players.each { |player| player.add_action_message(text) }
    end

    def broadcast_alert(text)
      players.each { |player| player.add_alert_message(text) }
    end
  end
end
