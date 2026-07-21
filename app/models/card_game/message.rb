module CardGame
  class Message
    include Serializable

    attr_accessor :type, :text

    def initialize(type = nil, text = nil)
      @type = type
      @text = text
    end

    serializes :type, :text

    def self.load(hash)
      message = super
      message&.tap { |loaded| loaded.type = loaded.type&.to_sym }
    end
  end
end
