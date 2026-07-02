class Game < ApplicationRecord
  enum :game_type, { "Go Fish": 0, "Secret Hitler": 1 }
end
