import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hand-arrival". Marks any hand card that
// wasn't there on the previous render as .hand-card--arriving, then drops
// the class a frame later so the transform transition already declared on
// .playing-card animates it settling into place — the same transition that
// animates a select/deselect. See hand_card.css for the raised start state.
//
// Listed after hand-sort in .hand-dock's data-controller so it connects
// second: hand-sort's resort has already placed every card (including the
// arrival, whichever sorted slot it landed in) before this runs. Moving the
// arrival to the end of the fan here happens in that same synchronous pass,
// before the browser paints, so the other cards never visibly snap — the
// only thing that visibly moves is the arrival settling in.
export default class extends Controller {
  static values = { gameId: String, userId: String }

  connect() {
    const keys = this.currentKeys()
    const storedKeys = localStorage.getItem(this.storageKey)

    if (storedKeys) this.markArriving(keys.filter((key) => !JSON.parse(storedKeys).includes(key)))

    localStorage.setItem(this.storageKey, JSON.stringify(keys))
  }

  currentKeys() {
    return Array.from(this.element.querySelectorAll(".hand-card__input")).map((input) => input.value)
  }

  markArriving(keys) {
    const fan = this.element.querySelector(".hand-fan")
    const cards = keys.map((key) => {
      const card = this.cardFor(key)
      fan.append(card)
      return card
    })

    cards.forEach((card) => card.classList.add("hand-card--arriving"))
    // A transition cannot fire on first paint, so the class is applied here
    // and removed one frame later — that manufactures the "from" state the
    // transition needs to animate from.
    requestAnimationFrame(() => cards.forEach((card) => card.classList.remove("hand-card--arriving")))
  }

  cardFor(key) {
    return this.element.querySelector(`.hand-card__input[value="${key}"]`).closest(".hand-card")
  }

  get storageKey() {
    return `rummy-hand:${this.gameIdValue}:${this.userIdValue}`
  }
}
