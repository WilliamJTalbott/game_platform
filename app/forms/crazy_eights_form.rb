class CrazyEightsForm
  include ActiveModel::Model

  attr_accessor :game, :card, :suit

  validates :card, presence: true
  validate :card_belongs_to_active_player
  validate :card_can_be_played
  validate :wild_card_has_valid_suit

  private

  def parsed_card
    @parsed_card ||= CardGame::Card.from_s(card)
  end

  def card_belongs_to_active_player
    return if card.blank?
    return if game.active_player.cards.include?(parsed_card)

    errors.add(:card, "is not in the player's hand")
  end

  def card_can_be_played
    return if errors.include?(:card)
    return if game.discard.wild?(parsed_card) || game.discard.valid_play?(parsed_card)

    errors.add(:card, "cannot be legally played")
  end

  def wild_card_has_valid_suit
    return if errors.include?(:card)
    return unless game.discard.wild?(parsed_card)
    return if CardGame::Card::SUITS.include?(suit)

    errors.add(:suit, "must be selected when playing an eight")
  end
end
