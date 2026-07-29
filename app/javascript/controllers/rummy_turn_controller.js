import { Controller } from "@hotwired/stimulus"
import { isMeld, canAdd } from "../rummy_melds"

// Connects to data-controller="rummy-turn"
export default class extends Controller {
  static targets = [
    "action", "meldIndex", "cardInput", "discardPile", "meldPlaceholder", "meld",
    "meldStep", "discardStep"
  ]
  static values = { phase: String }

  draw({ params: { action } }) {
    this.actionTarget.value = this.phaseValue === "meld" && action === "draw_discard" ? "discard" : action
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

  refresh() {
    const checked = this.checkedInputs
    const selection = checked.map((input) => this.cardFor(input))

    this.meldPlaceholderTarget.hidden = !isMeld(selection)
    // A meld target only exists on melds the player is allowed to lay off onto
    // (RummyGamePresenter#can_lay_off?) — the server-authoritative rule is
    // mirrored here only to decide whether the selection legally extends it.
    this.meldTargets.forEach((meld) => {
      meld.disabled = checked.length === 0 || !canAdd(this.meldCardsFor(meld), selection)
    })
    // A locked card (just drawn from the discard) can still join a meld, but
    // can't be discarded — so keep the discard pile disabled when it's the lone
    // selection. The server enforces the same rule.
    if (this.phaseValue === "meld") {
      const lockedAlone = checked.length === 1 && checked[0].dataset.locked === "true"
      const readyToDiscard = checked.length === 1 && !lockedAlone
      this.discardPileTarget.disabled = !readyToDiscard
      // A single card can go either way — laid off onto a meld or discarded —
      // so both steps light up together rather than one replacing the other.
      this.discardStepTarget.classList.toggle("phase-stepper__step--active", readyToDiscard)
    }
  }

  get checkedInputs() {
    return this.cardInputTargets.filter((input) => input.checked)
  }

  cardFor(input) {
    const { rankValue, suitIndex } = input.closest(".hand-card").dataset
    return { rankValue: Number(rankValue), suitIndex: Number(suitIndex) }
  }

  meldCardsFor(meld) {
    return Array.from(meld.querySelectorAll(".meld__card")).map((card) => ({
      rankValue: Number(card.dataset.rankValue),
      suitIndex: Number(card.dataset.suitIndex)
    }))
  }
}
