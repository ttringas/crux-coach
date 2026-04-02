import { Controller } from "@hotwired/stimulus"

const SOFT_REFRESH_MS = 60_000
const HARD_REFRESH_MS = 210_000
const POLL_INTERVAL_MS = 4_000
const PROGRESS_TICK_MS = 700
const MESSAGE_TICK_MS = 5_500
const DEFAULT_WEEKS = 8
const MAX_WEEKS = 12

export default class extends Controller {
  static targets = [
    "button",
    "pending",
    "progressFill",
    "progressLabel",
    "statusMessage",
    "startDate",
    "endDate",
    "dateHelper",
    "dateError"
  ]
  static values = {
    statusUrl: String,
    generationTargetId: String
  }

  connect() {
    this.refreshTimeouts = []
    this.pollInterval = null
    this.progressInterval = null
    this.messageInterval = null
    this.progressValue = 6
    this.messageIndex = 0
    this.activeGeneration = false

    this.syncDateRange({ resetEndDate: !this.hasEndDateTarget || !this.endDateTarget.value })

    if (this.hasPendingTarget) {
      this.startGenerationUx()
    }
  }

  disconnect() {
    this.clearRefreshTimeouts()
    this.stopPolling()
    this.stopProgress()
    this.stopMessages()
  }

  submit(event) {
    this.syncDateRange()

    if (this.hasDateErrorTarget && this.dateErrorTarget.textContent.trim().length > 0) {
      event.preventDefault()
      return
    }

    this.scheduleRefreshFallbacks()
    this.startGenerationUx()

    // Defer disabling the button so the native form submit fires first
    setTimeout(() => {
      if (this.hasButtonTarget) {
        this.buttonTarget.disabled = true
        this.buttonTarget.classList.add("opacity-50")
        this.buttonTarget.textContent = "Generating plan…"
      }
    }, 50)
  }

  startDateChanged() {
    this.syncDateRange({ resetEndDate: true })
  }

  endDateChanged() {
    this.syncDateRange({ preserveManualEndDate: true })
  }

  pendingTargetConnected() {
    if (this.activeGeneration) {
      this.startProgress()
      this.startMessages()
    }
  }

  syncDateRange(options = {}) {
    if (!this.hasStartDateTarget || !this.hasEndDateTarget) return

    const startDate = this.parseDate(this.startDateTarget.value)
    if (!startDate) {
      this.showDateError("Pick a valid start date.")
      this.updateDateHelper()
      return
    }

    const maxEndDate = this.addWeeks(startDate, MAX_WEEKS)
    const desiredDefaultEndDate = this.addWeeks(startDate, DEFAULT_WEEKS)

    if (options.resetEndDate || !this.endDateTarget.value) {
      this.endDateTarget.value = this.formatDate(desiredDefaultEndDate)
    }

    let endDate = this.parseDate(this.endDateTarget.value)
    if (!endDate) {
      this.showDateError("Pick a valid end date.")
      this.updateDateHelper(startDate, null)
      return
    }

    if (endDate < startDate) {
      endDate = desiredDefaultEndDate
      this.endDateTarget.value = this.formatDate(endDate)
      this.showDateError("End date can’t be earlier than start date, so I reset it to 8 weeks later.")
      this.updateDateHelper(startDate, endDate)
      return
    }

    if (endDate > maxEndDate) {
      endDate = maxEndDate
      this.endDateTarget.value = this.formatDate(endDate)
      this.showDateError(`Max range is 12 weeks, so I capped the end date at ${this.endDateTarget.value}.`)
      this.updateDateHelper(startDate, endDate)
      return
    }

    this.clearDateError()
    this.updateDateHelper(startDate, endDate)
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

  startGenerationUx() {
    if (this.activeGeneration) return

    this.activeGeneration = true
    this.startProgress()
    this.startMessages()
    this.startPolling()
  }

  startProgress() {
    if (!this.hasProgressFillTarget) return
    if (this.progressInterval) return

    this.updateProgress()
    this.progressInterval = window.setInterval(() => {
      const cap = 94
      const increment =
        this.progressValue < 55 ? 2.5 : this.progressValue < 75 ? 1.2 : this.progressValue < 88 ? 0.6 : 0.25
      this.progressValue = Math.min(cap, this.progressValue + increment)
      this.updateProgress()
    }, PROGRESS_TICK_MS)
  }

  stopProgress() {
    if (!this.progressInterval) return
    window.clearInterval(this.progressInterval)
    this.progressInterval = null
  }

  updateProgress() {
    if (!this.hasProgressFillTarget) return

    const rounded = Math.round(this.progressValue)
    this.progressFillTarget.style.width = `${rounded}%`
    if (this.hasProgressLabelTarget) {
      this.progressLabelTarget.textContent = `${rounded}%`
    }
  }

  startMessages() {
    if (!this.hasStatusMessageTarget) return
    if (this.messageInterval) return

    const messages = this.messages()
    this.statusMessageTarget.textContent = messages[this.messageIndex % messages.length]

    this.messageInterval = window.setInterval(() => {
      this.messageIndex += 1
      this.statusMessageTarget.textContent = messages[this.messageIndex % messages.length]
    }, MESSAGE_TICK_MS)
  }

  stopMessages() {
    if (!this.messageInterval) return
    window.clearInterval(this.messageInterval)
    this.messageInterval = null
  }

  startPolling() {
    if (!this.statusUrlValue) return
    if (this.pollInterval) return

    this.pollInterval = window.setInterval(() => this.pollStatus(), POLL_INTERVAL_MS)
  }

  stopPolling() {
    if (!this.pollInterval) return
    window.clearInterval(this.pollInterval)
    this.pollInterval = null
  }

  async pollStatus() {
    if (!this.statusUrlValue) return

    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) return

      const payload = await response.json()

      if (payload.status === "pending" || payload.status === "idle") {
        return
      }

      this.stopPolling()
      this.stopProgress()
      this.stopMessages()
      this.activeGeneration = false

      if (payload.status === "completed") {
        this.progressValue = 100
        this.updateProgress()
      }

      if (payload.html && this.generationTargetIdValue) {
        const container = document.getElementById(this.generationTargetIdValue)
        if (container) {
          container.outerHTML = payload.html
        }
      }
    } catch (error) {
      // Ignore polling errors; the refresh fallback will handle recovery.
    }
  }

  updateDateHelper(startDate = this.parseDate(this.startDateTarget?.value), endDate = this.parseDate(this.endDateTarget?.value)) {
    if (!this.hasDateHelperTarget) return

    if (!startDate || !endDate) {
      this.dateHelperTarget.textContent = "Select a start and end date to preview the block length."
      return
    }

    const dayDiff = Math.max(1, Math.round((endDate - startDate) / 86_400_000))
    const weeks = Math.max(1, Math.round(dayDiff / 7))
    this.dateHelperTarget.textContent = `Selected range: about ${weeks} week${weeks === 1 ? "" : "s"}.`
  }

  showDateError(message) {
    if (!this.hasDateErrorTarget) return

    this.dateErrorTarget.textContent = message
    this.dateErrorTarget.classList.remove("hidden")
    this.endDateTarget.classList.add("border-red-400")
  }

  clearDateError() {
    if (this.hasDateErrorTarget) {
      this.dateErrorTarget.textContent = ""
      this.dateErrorTarget.classList.add("hidden")
    }

    if (this.hasEndDateTarget) {
      this.endDateTarget.classList.remove("border-red-400")
    }
  }

  parseDate(value) {
    if (!value) return null

    const [year, month, day] = value.split("-").map(Number)
    if (!year || !month || !day) return null

    return new Date(year, month - 1, day)
  }

  addWeeks(date, weeks) {
    const nextDate = new Date(date)
    nextDate.setDate(nextDate.getDate() + (weeks * 7))
    return nextDate
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = `${date.getMonth() + 1}`.padStart(2, "0")
    const day = `${date.getDate()}`.padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  messages() {
    return [
      "Analyzing your goals and recent benchmarks…",
      "Optimizing the schedule around your available days…",
      "Factoring in recovery, intensity, and climbing volume…",
      "Dialing in exercises, sets, reps, and rest windows…",
      "Pressure-testing progression and deload timing…",
      "Polishing the plan so it reads like a real coach wrote it…"
    ]
  }
}
