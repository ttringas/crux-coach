import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL_MS = 4_000
const MAX_POLL_INTERVAL_MS = 20_000
const TIMEOUT_MS = 5 * 60 * 1_000
const STATUS_MESSAGES = [
  "Reviewing your soreness ratings and notes…",
  "Pulling context from your last 3 sessions…",
  "Considering today's place in the training block…",
  "Picking exercises that protect what's sore…",
  "Calibrating sets, reps, and intensity…",
  "Almost done — finishing the prescription…"
]

export default class extends Controller {
  static targets = ["feedback", "submitButton", "submitLabel", "statusMessage", "recalibrateLink", "recalibrateForm"]
  static values = {
    statusUrl: String,
    status: { type: String, default: "idle" }
  }

  connect() {
    this.pollTimer = null
    this.timeoutTimer = null
    this.messageTimer = null
    this.messageIndex = 0
    this.currentPollIntervalMs = POLL_INTERVAL_MS

    if (this.statusValue === "in_progress") {
      this.startPolling()
      this.startMessageRotation()
      this.startTimeoutGuard()
    }
  }

  disconnect() {
    this.stopPolling()
    this.stopMessageRotation()
    this.stopTimeoutGuard()
  }

  submit(event) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      if (this.hasSubmitLabelTarget) {
        this.submitLabelTarget.textContent = "Calibrating…"
      }
    }
  }

  showRecalibrate(event) {
    event.preventDefault()
    if (this.hasRecalibrateFormTarget) {
      this.recalibrateFormTarget.classList.remove("hidden")
    }
    if (this.hasRecalibrateLinkTarget) {
      this.recalibrateLinkTarget.classList.add("hidden")
    }
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.focus()
    }
  }

  async revert(event) {
    event.preventDefault()
    const url = event.params?.revertUrl || event.currentTarget.dataset.sessionCalibratorRevertUrlParam
    if (!url) return

    const button = event.currentTarget
    button.disabled = true
    button.textContent = "Reverting…"

    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Accept": "text/html",
          "X-CSRF-Token": token,
          "Turbo-Frame": "_top"
        }
      })
      if (!response.ok) throw new Error("Revert failed")
      window.location.reload()
    } catch (err) {
      button.disabled = false
      button.textContent = "Revert failed — try again"
    }
  }

  startPolling() {
    if (!this.statusUrlValue) return
    this.schedulePoll()
  }

  schedulePoll() {
    if (this.pollTimer) return
    this.pollTimer = window.setTimeout(() => {
      this.pollTimer = null
      this.pollStatus()
    }, this.currentPollIntervalMs)
  }

  stopPolling() {
    if (!this.pollTimer) return
    window.clearTimeout(this.pollTimer)
    this.pollTimer = null
  }

  async pollStatus() {
    try {
      const response = await fetch(this.statusUrlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        this.handlePollError()
        return
      }
      this.currentPollIntervalMs = POLL_INTERVAL_MS
      const payload = await response.json()

      if (payload.status === "in_progress") {
        this.schedulePoll()
        return
      }

      this.stopPolling()
      this.stopMessageRotation()
      this.stopTimeoutGuard()
      window.location.reload()
    } catch (err) {
      this.handlePollError()
    }
  }

  handlePollError() {
    this.currentPollIntervalMs = Math.min(this.currentPollIntervalMs * 2, MAX_POLL_INTERVAL_MS)
    this.schedulePoll()
  }

  startMessageRotation() {
    if (!this.hasStatusMessageTarget) return
    this.messageTimer = window.setInterval(() => {
      this.messageIndex = (this.messageIndex + 1) % STATUS_MESSAGES.length
      this.statusMessageTarget.textContent = STATUS_MESSAGES[this.messageIndex]
    }, 4_000)
  }

  stopMessageRotation() {
    if (!this.messageTimer) return
    window.clearInterval(this.messageTimer)
    this.messageTimer = null
  }

  startTimeoutGuard() {
    this.timeoutTimer = window.setTimeout(() => {
      this.stopPolling()
      this.stopMessageRotation()
      window.location.reload()
    }, TIMEOUT_MS)
  }

  stopTimeoutGuard() {
    if (!this.timeoutTimer) return
    window.clearTimeout(this.timeoutTimer)
    this.timeoutTimer = null
  }
}
