module GoFish
  class TurnResult
    attr_accessor :players, :current_player, :target_player, :target_rank, :went_fishing

    def initialize(players, current_player, target_player, target_rank)
      @players = players
      @current_player = current_player
      @target_player = target_player
      @target_rank = target_rank
      @went_fishing = false

      asked_for_card
    end

    # TurnResults holds second person and third person message methods
    # When a message needs to be added it calls a general method like: add_got_messages
    # This method loops over passed in players and gives them all the message

    def got_cards(card_count)
      players.each do |player|
        next player.add_normal_message(got_message_attacking(card_count)) if player == current_player
        next player.add_alert_message(got_message_defending(card_count)) if player == target_player
        player.add_normal_message(got_message_viewer(card_count))
      end
    end

    def go_fish

    self.went_fishing = true

      players.each do |player|
        next player.add_alert_message(go_fish_message_attacking) if player == current_player
        next player.add_normal_message(go_fish_message_defending) if player == target_player
        player.add_normal_message(go_fish_message_viewer)
      end
    end

    def winner(winner)
      players.each do |player|
        next player.add_alert_message(winner_message_secondperson) if player == winner
        player.add_alert_message(winner_message_thirdperson(winner))
      end
    end

    def drew_card(card)
      players.each do |player|
        if card.rank == target_rank
          next player.add_alert_message(repeat_message_secondperson) if player == current_player
          player.add_alert_message(repeat_message_thirdperson)
        else
          next player.add_normal_message(drew_message_secondperson(card)) if player == current_player
          player.add_normal_message(drew_message_thirdperson)
        end
      end
    end

    def as_json
      {
        'current_player' => current_player,
        'rank' => target_rank,
        'went_fishing' => went_fishing,
        'display' => "No Output messages for bot yet...",
      }
    end

    private

    def asked_for_card
      players.each do |player|
        next player.add_action_message(asked_message_attacking) if player == current_player
        next player.add_action_message(asked_message_defending) if player == target_player
        player.add_action_message(asked_message_viewer)
      end
    end

    def asked_message_attacking = "You asked #{target_player.name} for #{target_rank}'s."
    def asked_message_defending = "#{current_player.name} asked you for #{target_rank}'s."
    def asked_message_viewer = "#{current_player.name} asked #{target_player.name} for #{target_rank}'s."

    def got_message_attacking(card_count) = "You got #{card_count} #{target_rank}'s from #{target_player.name}."
    def got_message_defending(card_count) = "#{current_player.name} took #{card_count} #{target_rank}'s from you."
    def got_message_viewer(card_count) = "#{current_player.name} got #{card_count} #{target_rank}'s from #{target_player.name}."

    def go_fish_message_attacking = "#{target_player.name} didn't have any #{target_rank}'s. Go fish!"
    def go_fish_message_defending = "You didn't have any #{target_rank}'s. #{current_player.name} goes fish!"
    def go_fish_message_viewer = "#{target_player.name} didn't have any #{target_rank}'s. #{current_player.name} goes fish!"

    def drew_message_secondperson(card) = "You drew a #{card}."
    def drew_message_thirdperson = "#{current_player.name} drew a card"

    def repeat_message_secondperson = "You drew the card you asked for! Go again!"
    def repeat_message_thirdperson = "#{current_player.name} drew the card they asked for and gets to go again!"

    def winner_message_secondperson = "You win!"
    def winner_message_thirdperson(winner) = "#{winner.name} wins!"

  end
end