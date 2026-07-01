class Game < ApplicationRecord
  enum :type, { go_fish: 0, secret_hitler: 1 }
end
