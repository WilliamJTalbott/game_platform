import { Controller } from "@hotwired/stimulus"

const SORTS = {
  rank: (a, b) => a.rankValue - b.rankValue,
  suit: (a, b) => a.suitIndex - b.suitIndex || a.rankIndex - b.rankIndex
}

// Connects to data-controller="hand-sort"
export default class extends Controller {
  static values = { gameId: String, userId: String }

  connect() {
    const savedMode = localStorage.getItem(this.storageKey)
    this.applySort(savedMode || "rank")
  }

  sort(event) {
    const { mode } = event.params
    this.applySort(mode)
    localStorage.setItem(this.storageKey, mode)
  }

  applySort(mode) {
    const fan = this.element.querySelector(".hand-fan")
    // A stale localStorage mode from an older build would otherwise throw here.
    if (!fan || !SORTS[mode]) return

    const cards = Array.from(fan.querySelectorAll(".hand-card"))
    cards.sort((a, b) => SORTS[mode](a.dataset, b.dataset))
    fan.append(...cards)
  }

  get storageKey() {
    return `rummy-hand-sort:${this.gameIdValue}:${this.userIdValue}`
  }
}
