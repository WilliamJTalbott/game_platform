import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
export default class extends Controller {
    static values = { value: String }

    async copy() {
        await navigator.clipboard.writeText(this.valueValue)

        // Capture the label only on the first click — a second click inside the window
        // would otherwise capture "Copied!" and keep it as the label forever.
        this.originalLabel ??= this.element.textContent
        this.element.textContent = "Copied!"

        clearTimeout(this.resetTimer)
        this.resetTimer = setTimeout(() => this.restore(), 1500)
    }

    disconnect() {
        clearTimeout(this.resetTimer)
    }

    restore() {
        this.element.textContent = this.originalLabel
        this.originalLabel = undefined
    }
}
