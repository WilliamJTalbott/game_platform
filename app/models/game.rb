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

  def duration

    total_seconds = (self.started_at - self.finished_at).to_i
    return unless total_seconds

    hours = total_seconds / 3600
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60

    [hours, minutes, seconds].map { |t| t.to_s.rjust(2, '0') }.join(':')

  end

end
