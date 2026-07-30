import { Controller } from "@hotwired/stimulus"

const KEY_PREFIX = "rummy-hand:"
const RETENTION_MS = 7 * 24 * 60 * 60 * 1000

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
    const previousKeys = this.previousKeys()

    if (previousKeys) this.markArriving(keys.filter((key) => !previousKeys.includes(key)))

    localStorage.setItem(this.storageKey, JSON.stringify({ keys, at: Date.now() }))
    this.pruneStaleHands()
  }

  previousKeys() {
    const stored = JSON.parse(localStorage.getItem(this.storageKey) || "null")
    // An entry written before this key carried a timestamp reads as absent:
    // one render without an arrival animation, then it's rewritten in the
    // current shape. Cheaper than a migration for a purely cosmetic cue.
    return Array.isArray(stored?.keys) ? stored.keys : null
  }

  // One entry is written per game per user, and nothing else ever removes them,
  // so every finished game would leave its last hand behind forever. A game
  // still being played rewrites its own entry on every render, so only hands
  // untouched for RETENTION_MS — finished or abandoned games — age out here.
  pruneStaleHands() {
    const cutoff = Date.now() - RETENTION_MS

    Object.keys(localStorage)
      .filter((key) => key.startsWith(KEY_PREFIX))
      .filter((key) => !(JSON.parse(localStorage.getItem(key))?.at > cutoff))
      .forEach((key) => localStorage.removeItem(key))
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
