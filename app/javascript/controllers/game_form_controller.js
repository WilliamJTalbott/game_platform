import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game-form"
export default class extends Controller {
    static targets = [ "button" ]
    submitForm(event) {
        this.buttonTarget.click();
    }
}
