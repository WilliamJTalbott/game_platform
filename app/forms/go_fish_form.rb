class GoFishForm
  include ActiveModel::Model

  attr_accessor :player_name, :rank

  validates :player_name, presence: true
  validates :rank, presence: true

  private

end