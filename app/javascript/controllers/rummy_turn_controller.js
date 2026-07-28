import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [
    "action", "meldIndex", "cardInput", "discardPile", "meldPlaceholder", "meld"
  ]
  static values = { phase: String }

  draw({ params: { action } }) {
    this.actionTarget.value = this.phaseValue === "meld" && action === "draw_discard" ? "discard" : action
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }

  meld() {
    this.actionTarget.value = "meld"
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }

  layOff({ params: { meldIndex } }) {
    this.actionTarget.value = "lay_off"
    this.meldIndexTarget.value = meldIndex
    this.element.requestSubmit()
  }

  refresh() {
    const checked = this.checkedInputs

    this.meldPlaceholderTarget.hidden = checked.length < 3
    // Laying off is meaningless without a selection, so the existing melds stay
    // disabled until you have picked at least one card. Whether the selection is
    // a LEGAL extension of a given meld is still the server's call — the flash
    // reports it — so this gates on "is there anything to lay off" only.
    this.meldTargets.forEach((meld) => { meld.disabled = checked.length === 0 })
    // A locked card (just drawn from the discard) can still join a meld, but
    // can't be discarded — so keep the discard pile disabled when it's the lone
    // selection. The server enforces the same rule.
    if (this.phaseValue === "meld") {
      const lockedAlone = checked.length === 1 && checked[0].dataset.locked === "true"
      this.discardPileTarget.disabled = checked.length !== 1 || lockedAlone
    }
  }

  get checkedInputs() {
    return this.cardInputTargets.filter((input) => input.checked)
  }
}
