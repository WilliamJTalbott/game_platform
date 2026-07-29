import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "sort", "minimumGames"]

  connect() {
    this.debounceTimer = null
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }

  submit() {
    this.formTarget.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.submit(), 300)
  }

  sort(event) {
    const { sort, minimumGames } = event.params

    this.sortTarget.value = sort
    this.activateButton(event.currentTarget)

    if (minimumGames && Number(this.minimumGamesTarget.value) < Number(minimumGames)) {
      this.minimumGamesTarget.value = minimumGames
    }

    this.submit()
  }

  activateButton(button) {
    this.element.querySelectorAll(".btn--active").forEach(active => active.classList.remove("btn--active"))
    button.classList.add("btn--active")
  }
}
