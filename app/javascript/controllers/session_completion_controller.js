import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statusLabel", "startButton", "completeButton", "skipButton"]
  static values = { url: String }

  start() {
    this.updateStatus("in_progress")
  }

  complete() {
    this.updateStatus("completed")
  }

  skip() {
    this.updateStatus("skipped")
  }

  async updateStatus(status) {
    if (!this.urlValue) return

    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ planned_session: { status: status } })
      })

      if (!response.ok) throw new Error("Status update failed")
      const data = await response.json()
      this.applyStatus(data.status || status)
      this.element.dispatchEvent(new CustomEvent("session-status:updated", { detail: data, bubbles: true }))
    } catch (error) {
      // no-op
    }
  }

  applyStatus(status) {
    if (this.hasStatusLabelTarget) {
      this.statusLabelTarget.textContent = status.replace(/_/g, " ")
    }

    if (this.hasStartButtonTarget) {
      this.startButtonTarget.classList.toggle("hidden", status !== "todo")
    }
    if (this.hasCompleteButtonTarget) {
      this.completeButtonTarget.classList.toggle("hidden", status !== "in_progress")
    }
    if (this.hasSkipButtonTarget) {
      this.skipButtonTarget.classList.toggle("hidden", status === "completed" || status === "skipped")
    }
  }
}
