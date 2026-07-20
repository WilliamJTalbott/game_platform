import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game-form"
export default class extends Controller {
    static targets = [ "button" ]
    submitForm(event) {
        console.log("SEND FORM")
        this.buttonTarget.click();
    }
}
