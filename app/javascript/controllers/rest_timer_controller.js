import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "ring"]
  static values = { duration: Number }

  connect() {
    this.resetDisplay()
  }

  disconnect() {
    this.stopTimer()
  }

  start() {
    this.stopTimer()
    this.total = this.durationValue || 60
    this.remaining = this.total
    this.updateDisplay()

    this.timer = setInterval(() => {
      this.remaining -= 1
      if (this.remaining <= 0) {
        this.remaining = 0
        this.updateDisplay()
        this.stopTimer()
        this.pulse()
      } else {
        this.updateDisplay()
      }
    }, 1000)
  }

  stopTimer() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  resetDisplay() {
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = "0:00"
    }
    if (this.hasRingTarget) {
      this.ringTarget.style.background = "conic-gradient(#f59e0b 0deg, rgba(148, 163, 184, 0.2) 0deg)"
    }
  }

  updateDisplay() {
    if (this.hasDisplayTarget) {
      const minutes = Math.floor(this.remaining / 60)
      const seconds = this.remaining % 60
      this.displayTarget.textContent = `${minutes}:${String(seconds).padStart(2, "0")}`
    }
    this.updateRing()
  }

  updateRing() {
    if (!this.hasRingTarget || !this.total) return
    const progress = ((this.total - this.remaining) / this.total) * 360
    this.ringTarget.style.background = `conic-gradient(#f59e0b ${progress}deg, rgba(148, 163, 184, 0.2) ${progress}deg)`
  }

  pulse() {
    if (!this.hasRingTarget) return
    this.ringTarget.classList.add("animate-pulse")
    setTimeout(() => {
      this.ringTarget.classList.remove("animate-pulse")
    }, 2000)
  }
}
