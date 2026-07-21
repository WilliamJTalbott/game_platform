import { Controller } from "@hotwired/stimulus"

const OVERLAP_RATIO = 0.4

// Connects to data-controller="hand"
export default class extends Controller {
  static targets = [ "card" ]

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.updateOverlap())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.resizeObserver.disconnect()
  }

  updateOverlap() {
    if (this.cardTargets.length === 0) return

    const cardWidth = this.cardTargets[0].getBoundingClientRect().width
    this.element.style.setProperty("--gf-card-overlap", `${-OVERLAP_RATIO * cardWidth}px`)
  }
}
