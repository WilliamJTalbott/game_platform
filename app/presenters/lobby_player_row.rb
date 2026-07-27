class LobbyPlayerRow
  attr_reader :name

  def initialize(name:, host:, you:)
    @name = name
    @host = host
    @you = you
  end

  def host? = @host
  def you? = @you
end
