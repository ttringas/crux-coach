import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "ring", "toggleButton"]
  static values = { duration: { type: Number, default: 60 } }

  connect() {
    this.remaining = 0
    this.running = false
    this.intervalId = null
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId)
  }

  toggle() {
    if (this.running) {
      this.stop()
    } else {
      this.start()
    }
  }

  start() {
    this.remaining = this.durationValue
    this.running = true

    // Show display and ring
    if (this.hasDisplayTarget) this.displayTarget.classList.remove("hidden")
    if (this.hasRingTarget) this.ringTarget.classList.remove("hidden")
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.textContent = "Stop"
      this.toggleButtonTarget.classList.add("bg-amber-500/10")
    }

    this.render()
    this.intervalId = setInterval(() => this.tick(), 1000)
  }

  stop() {
    this.running = false
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.textContent = `Rest ${this.formatTime(this.durationValue)}`
      this.toggleButtonTarget.classList.remove("bg-amber-500/10")
    }
    if (this.hasDisplayTarget) this.displayTarget.classList.add("hidden")
    if (this.hasRingTarget) this.ringTarget.classList.add("hidden")
  }

  tick() {
    this.remaining -= 1
    this.render()

    if (this.remaining <= 0) {
      this.finish()
    }
  }

  finish() {
    clearInterval(this.intervalId)
    this.intervalId = null
    this.running = false

    // Pulse animation
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = "Done!"
      this.displayTarget.classList.add("text-emerald-400")
      setTimeout(() => {
        this.displayTarget.classList.remove("text-emerald-400")
        this.displayTarget.classList.add("hidden")
        if (this.hasRingTarget) this.ringTarget.classList.add("hidden")
      }, 2000)
    }
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.textContent = `Rest ${this.formatTime(this.durationValue)}`
      this.toggleButtonTarget.classList.remove("bg-amber-500/10")
    }
  }

  render() {
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = this.formatTime(this.remaining)
    }
    if (this.hasRingTarget) {
      const progress = 1 - (this.remaining / this.durationValue)
      const degrees = Math.round(progress * 360)
      this.ringTarget.style.background = `conic-gradient(rgb(245 158 11) ${degrees}deg, rgb(30 41 59 / 0.4) ${degrees}deg)`
    }
  }

  formatTime(seconds) {
    const m = Math.floor(Math.abs(seconds) / 60)
    const s = Math.abs(seconds) % 60
    return `${m}:${s.toString().padStart(2, "0")}`
  }
}
