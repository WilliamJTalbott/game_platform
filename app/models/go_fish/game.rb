module GoFish
  class Game

    attr_accessor :players

    def initialize(players)
      @players = players
    end

    def self.load(json)
      return if json.blank?
      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end

    def as_json(*)
      {
        players: players.map(&:as_json),
      }
    end

    def self.from_json(json)
      players = json[:players].map { |player_hash| Player.load(player_hash) }
      self.new(players)
    end

  end
end

# 

# User visits POST: turn#create(game_id:47)
# TurnController.create(game) runs turn if valid and calls Game.save
# Game.save 

# Game.new(players) -> setup game for turn
# Game.play_turn(params) -> executes logic and dumps game into database
# 
#
# Game.dump -> turns it into json
# Game.load -> turns it into object
# 
# 