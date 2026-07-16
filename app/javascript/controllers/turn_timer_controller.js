import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turn-timer"
export default class extends Controller {
    static targets = [ "display" ]

    connect() {
        this.timeLeft = 5
        this.updateDisplay()

        this.timer = setInterval(() => { this.tick() }, 1000)
    }

    tick() {
        this.timeLeft--
        this.updateDisplay()

        if (this.timeLeft === 0) {
            clearInterval(this.timer)
            this.timerOver()
        }
    }

    timerOver() {
        console.log("DISPATCH")
        this.dispatch("ended")
    }

    updateDisplay() {
        console.log("UPDATING DISPLAY")
        this.displayTarget.textContent = this.timeLeft
    }
}
