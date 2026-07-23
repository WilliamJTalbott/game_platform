import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [ "action", "card" ]

  draw({ params: { action } }) {
    this.actionTarget.value = action
    this.cardTarget.value = ""
    this.element.requestSubmit()
  }

  discard({ params: { card } }) {
    this.actionTarget.value = "discard"
    this.cardTarget.value = card
    this.element.requestSubmit()
  }
}
