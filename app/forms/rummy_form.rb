class RummyForm
  include ActiveModel::Model

  ACTIONS = %w[draw_stock draw_discard toggle_select meld lay_off discard]
  DRAW_ACTIONS = %w[draw_stock draw_discard]

  attr_accessor :game, :action, :card, :meld_index

  validates :action, inclusion: { in: ACTIONS }

  validate :action_matches_phase
  validate :discard_pile_has_a_card, if: -> { action == "draw_discard" }
  validate :card_is_in_hand, if: -> { action == "toggle_select" }
  validate :selection_forms_a_valid_meld, if: -> { action == "meld" }
  validate :lay_off_targets_a_valid_meld, if: -> { action == "lay_off" }
  validate :exactly_one_card_is_selected, if: -> { action == "discard" }

  private

  def action_matches_phase
    return if action.blank?

    expected_phase = DRAW_ACTIONS.include?(action) ? "draw" : "meld"
    errors.add(:action, "is not allowed during the #{game.phase} phase") unless game.phase == expected_phase
  end

  def discard_pile_has_a_card
    errors.add(:base, "there is no card on the discard pile to draw") if game.discard.top.nil?
  end

  def card_is_in_hand
    errors.add(:card, "must be a card in your hand") if selected_card.nil?
  end

  def selection_forms_a_valid_meld
    return if Rummy::Meld.valid?(game.active_player.selected)

    errors.add(:base, "select 3 or more cards that form a run or set")
  end

  def exactly_one_card_is_selected
    errors.add(:base, "select exactly one card to discard") unless game.active_player.selected.size == 1
  end

  def lay_off_targets_a_valid_meld
    return errors.add(:meld_index, "must reference an existing meld") if target_meld.nil?
    return if target_meld.can_add?(game.active_player.selected)

    errors.add(:base, "select cards that extend that meld legally")
  end

  def target_meld
    return nil if meld_index.blank?

    game.melds[meld_index.to_i]
  end

  def selected_card
    return nil if card.blank?

    rank, suit = card.split("-", 2)
    game.active_player.cards.find { |hand_card| hand_card.rank == rank && hand_card.suit == suit }
  end
end
