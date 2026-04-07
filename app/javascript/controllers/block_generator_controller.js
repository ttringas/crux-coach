import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL_MS = 4_000
const MAX_POLL_INTERVAL_MS = 30_000
const PROGRESS_TICK_MS = 700
const MESSAGE_TICK_MS = 5_500
const DEFAULT_WEEKS = 8
const MAX_WEEKS = 12
const GENERATION_TIMEOUT_MS = 10 * 60 * 1_000 // 10 minutes
const MAX_CONSECUTIVE_ERRORS = 5

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
    this.pollInterval = null
    this.progressInterval = null
    this.messageInterval = null
    this.generationTimeout = null
    this.progressValue = 6
    this.messageIndex = 0
    this.activeGeneration = false
    this.currentPollIntervalMs = POLL_INTERVAL_MS
    this.consecutiveErrors = 0

    this.syncDateRange({ resetEndDate: !this.hasEndDateTarget || !this.endDateTarget.value })

    if (this.hasPendingTarget) {
      this.startGenerationUx()
    }
  }

  disconnect() {
    this.stopPolling()
    this.stopProgress()
    this.stopMessages()
    this.stopGenerationTimeout()
  }

  submit(event) {
    this.syncDateRange()

    if (this.hasDateErrorTarget && this.dateErrorTarget.textContent.trim().length > 0) {
      event.preventDefault()
      return
    }

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
      this.showDateError("End date can't be earlier than start date, so I reset it to 8 weeks later.")
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

  refreshPage(notice = null) {
    const url = new URL(window.location.href)

    if (notice) {
      url.searchParams.set("generation_notice", notice)
    } else {
      url.searchParams.delete("generation_notice")
    }

    window.location.assign(url.toString())
  }

  startGenerationUx() {
    if (this.activeGeneration) return

    this.activeGeneration = true
    this.consecutiveErrors = 0
    this.currentPollIntervalMs = POLL_INTERVAL_MS
    this.startProgress()
    this.startMessages()
    this.startPolling()
    this.startGenerationTimeout()
  }

  startProgress() {
    if (!this.hasProgressFillTarget) return
    if (this.progressInterval) return

    this.updateProgress()
    this.progressInterval = window.setInterval(() => {
      const cap = 95
      // Reach ~95% over ~3.5 minutes (300 ticks at 700ms)
      const increment =
        this.progressValue < 30 ? 0.8 : this.progressValue < 60 ? 0.5 : this.progressValue < 80 ? 0.3 : this.progressValue < 90 ? 0.15 : 0.05
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

    this.schedulePoll()
  }

  schedulePoll() {
    if (this.pollInterval) return

    this.pollInterval = window.setTimeout(() => {
      this.pollInterval = null
      this.pollStatus()
    }, this.currentPollIntervalMs)
  }

  stopPolling() {
    if (!this.pollInterval) return
    window.clearTimeout(this.pollInterval)
    this.pollInterval = null
  }

  startGenerationTimeout() {
    if (this.generationTimeout) return

    this.generationTimeout = window.setTimeout(() => {
      this.stopPolling()
      this.stopProgress()
      this.stopMessages()
      this.activeGeneration = false
      this.showTimeoutError()
    }, GENERATION_TIMEOUT_MS)
  }

  stopGenerationTimeout() {
    if (!this.generationTimeout) return
    window.clearTimeout(this.generationTimeout)
    this.generationTimeout = null
  }

  showTimeoutError() {
    if (!this.generationTargetIdValue) return

    const container = document.getElementById(this.generationTargetIdValue)
    if (!container) return

    container.innerHTML = `
      <div class="rounded-xl border border-red-500/30 bg-red-500/5 p-4">
        <div class="text-xs uppercase tracking-wide text-red-300">Generation failed</div>
        <div class="text-sm text-slate-200 mt-1">Plan generation timed out. Please try again.</div>
        <div class="text-xs text-slate-400 mt-2">If this keeps happening, contact support.</div>
        <div class="mt-3">
          <button onclick="window.scrollTo({ top: 0, behavior: 'smooth' })" class="bg-amber-400 text-slate-950 px-4 py-2 rounded-md text-sm font-semibold hover:bg-amber-300 transition">
            Try Again
          </button>
        </div>
      </div>
    `
  }

  async pollStatus() {
    if (!this.statusUrlValue) return

    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) {
        this.handlePollError()
        return
      }

      // Reset backoff on successful response
      this.consecutiveErrors = 0
      this.currentPollIntervalMs = POLL_INTERVAL_MS

      const payload = await response.json()

      if (payload.status === "pending" || payload.status === "idle") {
        this.schedulePoll()
        return
      }

      this.stopPolling()
      this.stopProgress()
      this.stopMessages()
      this.stopGenerationTimeout()
      this.activeGeneration = false

      if (payload.status === "completed") {
        this.progressValue = 100
        this.updateProgress()
        this.refreshPage(payload.notice || "Your training block is ready.")
        return
      }

      if (payload.html && this.generationTargetIdValue) {
        const container = document.getElementById(this.generationTargetIdValue)
        if (container) {
          container.outerHTML = payload.html
        }
      }
    } catch (error) {
      this.handlePollError()
    }
  }

  handlePollError() {
    this.consecutiveErrors += 1

    // Exponential backoff: double interval on each error, cap at MAX_POLL_INTERVAL_MS
    this.currentPollIntervalMs = Math.min(
      this.currentPollIntervalMs * 2,
      MAX_POLL_INTERVAL_MS
    )

    // Show warning after too many consecutive errors
    if (this.consecutiveErrors >= MAX_CONSECUTIVE_ERRORS && this.hasStatusMessageTarget) {
      this.statusMessageTarget.textContent = "Having trouble connecting — your plan may still be generating…"
    }

    // Continue polling (job may still be running server-side)
    this.schedulePoll()
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
      "This can take several minutes — hang tight!",
      "Optimizing the schedule around your available days…",
      "Factoring in recovery, intensity, and climbing volume…",
      "Still working — building a detailed, personalized plan takes a bit…",
      "Dialing in exercises, sets, reps, and rest windows…",
      "Pressure-testing progression and deload timing…",
      "Almost there — polishing the plan so it reads like a real coach wrote it…"
    ]
  }
}
