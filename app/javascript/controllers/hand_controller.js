import { Controller } from "@hotwired/stimulus"

const MIN_OVERLAP_RATIO = 0.4

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
    if (cardWidth === 0) return

    const overlap = this.overlapFor(this.cardTargets.length, cardWidth)
    this.element.style.setProperty("--gf-card-overlap", `${-overlap}px`)
  }

  overlapFor(count, cardWidth) {
    const min = MIN_OVERLAP_RATIO * cardWidth
    if (count < 2) return min

    const needed = cardWidth - (this.rowWidth() - cardWidth) / (count - 1)
    return Math.min(cardWidth, Math.max(min, needed))
  }

  rowWidth() {
    const row = this.cardTargets[0].parentElement
    const styles = getComputedStyle(row)
    const padding = parseFloat(styles.paddingLeft) + parseFloat(styles.paddingRight)
    return row.clientWidth - padding
  }
}
