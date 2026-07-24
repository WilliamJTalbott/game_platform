import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [
    "action", "meldIndex", "cardInput", "discardPile", "meldPlaceholder"
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
    const count = this.checkedInputs.length

    this.meldPlaceholderTarget.hidden = count < 3
    if (this.phaseValue === "meld") this.discardPileTarget.disabled = count !== 1
  }

  get checkedInputs() {
    return this.cardInputTargets.filter((input) => input.checked)
  }
}
