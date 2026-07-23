import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [
    "action", "meldIndex", "cardInput", "confirmPop", "confirmPopText", "meldButton", "discardButton"
  ]

  draw({ params: { action } }) {
    this.actionTarget.value = action
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

  discardSelected() {
    this.actionTarget.value = "discard"
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }

  refresh() {
    const count = this.checkedInputs.length
    const canMeld = count >= 3
    const canDiscard = count === 1

    this.meldButtonTarget.hidden = !canMeld
    this.discardButtonTarget.hidden = !canDiscard
    this.confirmPopTarget.hidden = !canMeld && !canDiscard
    this.confirmPopTextTarget.textContent = canMeld
      ? `Create a meld with these ${count} cards?`
      : "Discard this card?"
  }

  get checkedInputs() {
    return this.cardInputTargets.filter((input) => input.checked)
  }
}
