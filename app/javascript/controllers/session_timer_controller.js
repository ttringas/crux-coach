import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { startedAt: String }

  connect() {
    this.tick = this.tick.bind(this)
    if (this.hasStartedAtValue && this.startedAtValue) {
      this.startTimer(this.startedAtValue)
    }
  }

  disconnect() {
    this.stopTimer()
  }

  statusUpdated(event) {
    const detail = event.detail || {}
    if (detail.status === "in_progress" && detail.started_at) {
      this.startTimer(detail.started_at)
    }

    if (detail.status === "completed" || detail.status === "skipped") {
      this.stopTimer()
    }
  }

  startTimer(startedAt) {
    this.startedAtValue = startedAt
    this.startedAt = new Date(startedAt)
    this.stopTimer()
    this.timer = setInterval(this.tick, 1000)
    this.tick()
  }

  stopTimer() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  tick() {
    if (!this.startedAt || !this.hasDisplayTarget) return
    const elapsed = Math.max(0, Math.floor((Date.now() - this.startedAt.getTime()) / 1000))
    this.displayTarget.textContent = this.formatElapsed(elapsed)
  }

  formatElapsed(seconds) {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const remaining = seconds % 60
    if (hours > 0) {
      return `${hours}:${String(minutes).padStart(2, "0")}:${String(remaining).padStart(2, "0")}`
    }
    return `${minutes}:${String(remaining).padStart(2, "0")}`
  }
}
