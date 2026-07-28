import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
//
// Adds .show a frame after connecting, then takes it off again after a beat, so
// the notice slides in and slides back out (see ui/popup.css for both).
//
// The deferral is load-bearing. A transition only fires on a CHANGE, so a popup
// server-rendered with .show already on would just appear at its final position
// with no entry animation at all. Adding the class after the browser has
// computed the parked state gives the transition something to move from — and
// the frame is nested twice because a single callback can still land inside the
// same style recalculation as the insertion.
//
// Turbo replaces the whole #flash container, so a second rejection arrives as a
// fresh element with a fresh timer and a replayed slide, rather than reusing a
// node whose timer is already half spent.
export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    this.frame = requestAnimationFrame(() => {
      this.frame = requestAnimationFrame(() => this.element.classList.add("show"))
    })
    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.remove("show")
  }
}
