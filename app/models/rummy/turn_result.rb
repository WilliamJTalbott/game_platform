module Rummy
  class TurnResult
    def initialize(players, actor)
      @players = players
      @actor = actor
    end

    def drew_from_stock(card)
      broadcast("You drew #{card} from the stock.", "#{actor.name} drew from the stock.")
    end

    def drew_from_discard(card)
      broadcast("You drew #{card} from the discard.", "#{actor.name} drew #{card} from the discard.")
    end

    def discarded(card)
      broadcast("You discarded #{card}.", "#{actor.name} discarded #{card}.")
    end

    def winner
      broadcast("You emptied your hand and won!", "#{actor.name} emptied their hand and won!")
    end

    private

    attr_reader :players, :actor

    def broadcast(actor_message, onlooker_message)
      players.each do |player|
        player.add_normal_message(player == actor ? actor_message : onlooker_message)
      end
    end
  end
end
