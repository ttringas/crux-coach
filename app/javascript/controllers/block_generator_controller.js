import { Controller } from "@hotwired/stimulus"

const SOFT_REFRESH_MS = 45_000
const HARD_REFRESH_MS = 180_000

export default class extends Controller {
  static targets = ["button", "status", "startDate", "endDate"]

  connect() {
    this.refreshTimeouts = []
  }

  disconnect() {
    this.clearRefreshTimeouts()
  }

  submit() {
    if (this.hasStatusTarget) {
      this.statusTarget.classList.remove("hidden")
    }

    this.scheduleRefreshFallbacks()

    // Defer disabling the button so the native form submit fires first
    setTimeout(() => {
      if (this.hasButtonTarget) {
        this.buttonTarget.disabled = true
        this.buttonTarget.classList.add("opacity-50")
        this.buttonTarget.textContent = "Generating plan…"
      }
    }, 50)
  }

  scheduleRefreshFallbacks() {
    this.clearRefreshTimeouts()

    this.refreshTimeouts = [
      window.setTimeout(() => this.refreshPage(), SOFT_REFRESH_MS),
      window.setTimeout(() => this.refreshPage(), HARD_REFRESH_MS)
    ]
  }

  clearRefreshTimeouts() {
    if (!this.refreshTimeouts) return

    this.refreshTimeouts.forEach((timeoutId) => window.clearTimeout(timeoutId))
    this.refreshTimeouts = []
  }

  refreshPage() {
    window.location.reload()
  }
}
