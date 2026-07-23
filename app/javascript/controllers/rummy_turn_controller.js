import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [ "action", "card", "meldIndex" ]

  draw({ params: { action } }) {
    this.actionTarget.value = action
    this.cardTarget.value = ""
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }

  toggleSelect({ params: { card } }) {
    this.actionTarget.value = "toggle_select"
    this.cardTarget.value = card
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }

  meld() {
    this.actionTarget.value = "meld"
    this.cardTarget.value = ""
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }

  layOff({ params: { meldIndex } }) {
    this.actionTarget.value = "lay_off"
    this.cardTarget.value = ""
    this.meldIndexTarget.value = meldIndex
    this.element.requestSubmit()
  }

  discardSelected() {
    this.actionTarget.value = "discard"
    this.cardTarget.value = ""
    this.meldIndexTarget.value = ""
    this.element.requestSubmit()
  }
}
