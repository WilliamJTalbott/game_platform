import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        url: String
    }

    async connect() {
        if (!("serviceWorker" in navigator)) return

        try {
            this.registration = await navigator.serviceWorker.register(
                this.urlValue,
                { scope: "/" }
            )

            console.log("Service worker registered")
        } catch (error) {
            console.error("Service worker registration failed", error)
        }
    }
}