class Game < ApplicationRecord
  has_many :players
  enum :game_type, { "Go Fish": 0, "Secret Hitler": 1 }




  def start
    self.started_at = Time.current
  end

  def end
    self.finished_at = Time.current
  end

  def status
    return 'waiting' unless self.started_at
    return self.finished_at ? 'finished' : 'started'
  end
end
