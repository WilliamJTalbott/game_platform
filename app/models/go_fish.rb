class GoFish

  attr_accessor :players, :deck

  def initialize
    @players = []
    @deck = nil
    @index = 0
  end

  def deal!
  end

  def self.load(json)
    return if json.blank?
    from_json(json)
  end

  def self.dump(obj)
    obj.as_json.to_json
  end

  def as_json(*)
    {
      players: players.map(&:as_json),
      current_player_index: @index,
      deck: deck.as_json
    }
  end

  def self.from_json(json)
    instance = self.new
    hash = JSON.parse(json)
    return instance
  end

  private

  def build_players(hash)
    parsed_array.map { |user_hash| Player.new(user_hash) }
  end

end