import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [ "action", "card" ]

  draw({ params: { action } }) {
    this.actionTarget.value = action
    this.cardTarget.value = ""
    this.element.requestSubmit()
  }

  toggleSelect({ params: { card } }) {
    this.actionTarget.value = "toggle_select"
    this.cardTarget.value = card
    this.element.requestSubmit()
  }

  meld() {
    this.actionTarget.value = "meld"
    this.cardTarget.value = ""
    this.element.requestSubmit()
  }

  discardSelected() {
    this.actionTarget.value = "discard"
    this.cardTarget.value = ""
    this.element.requestSubmit()
  }
}
