module GoFish
  class Message
    attr_accessor :type, :text

    def initialize(type, text)
      @type = type
      @text = text
    end

    def as_json
      {
        "type" => type,
        "text" => text
      }
    end

    def self.load(hash)
      new(hash["type"].to_sym, hash["text"])
    end
  end
end
