import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["minutes", "seconds", "display", "startButton"]

  connect() {
    this.intervalId = null
    this.updateDisplay(this.totalSeconds())
  }

  disconnect() {
    this.stop()
  }

  start() {
    this.stop()
    const total = this.totalSeconds()
    if (total <= 0) return

    this.remaining = total
    this.updateDisplay(this.remaining)
    this.intervalId = setInterval(() => this.tick(), 1000)
  }

  tick() {
    this.remaining -= 1
    this.updateDisplay(this.remaining)

    if (this.remaining <= 0) {
      this.stop()
    }
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  totalSeconds() {
    const minutes = parseInt(this.minutesTarget?.value || "0", 10)
    const seconds = parseInt(this.secondsTarget?.value || "0", 10)
    const safeMinutes = Number.isNaN(minutes) ? 0 : Math.max(0, minutes)
    const safeSeconds = Number.isNaN(seconds) ? 0 : Math.max(0, seconds)
    return safeMinutes * 60 + safeSeconds
  }

  updateDisplay(seconds) {
    if (!this.hasDisplayTarget) return
    const safeSeconds = Math.max(0, seconds || 0)
    const minutes = Math.floor(safeSeconds / 60)
    const remaining = safeSeconds % 60
    this.displayTarget.textContent = `${minutes}:${String(remaining).padStart(2, "0")}`
  }
}
