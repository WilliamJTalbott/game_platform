import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "popup" ]

    connect() {
        this.updateStatus()
    }

    goOnline() {
        this.updateStatus()
    }

    goOffline() {
        this.updateStatus()
    }

    updateStatus() {
        if (navigator.onLine) {
            this.popupTarget.classList.remove("show")
        } else {
            this.popupTarget.classList.add("show")
        }
    }
}