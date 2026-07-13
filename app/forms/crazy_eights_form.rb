class CrazyEightsForm
  include ActiveModel::Model

  attr_accessor :card, :suit

  validates :card, presence: true
  validate :must_have_suit_if_wild

  private

  def must_have_suit_if_wild
  end

end