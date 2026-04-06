import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dayCell", "sessionList", "session"]

  connect() {
    this.draggedSession = null
    this.originList = null
    this.wasDragging = false

    this.sessionTargets.forEach((session) => {
      session.addEventListener("dragstart", this.handleDragStart.bind(this))
      session.addEventListener("dragend", this.handleDragEnd.bind(this))
    })

    this.sessionListTargets.forEach((list) => {
      list.addEventListener("dragover", this.handleDragOver.bind(this))
      list.addEventListener("drop", this.handleDrop.bind(this))
      list.addEventListener("dragenter", this.handleDragEnter.bind(this))
      list.addEventListener("dragleave", this.handleDragLeave.bind(this))
    })
  }

  handleDragStart(event) {
    this.draggedSession = event.currentTarget
    this.originList = this.draggedSession.parentElement
    this.wasDragging = true
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.draggedSession.dataset.sessionId)
    this.draggedSession.classList.add("opacity-50")
    this.sessionListTargets.forEach((list) => list.classList.add("ring-1", "ring-amber-400/20"))
  }

  handleDragEnd() {
    if (this.draggedSession) {
      this.draggedSession.classList.remove("opacity-50")
    }
    this.sessionListTargets.forEach((list) => list.classList.remove("ring-1", "ring-amber-400/20"))
    this.draggedSession = null
    this.originList = null
  }

  handleDragEnter(event) {
    event.preventDefault()
    event.currentTarget.closest("[data-monthly-drag-target='dayCell']")?.classList.add("border-amber-400")
  }

  handleDragLeave(event) {
    if (event.currentTarget.contains(event.relatedTarget)) return
    event.currentTarget.closest("[data-monthly-drag-target='dayCell']")?.classList.remove("border-amber-400")
  }

  handleDragOver(event) {
    event.preventDefault()
  }

  async handleDrop(event) {
    event.preventDefault()
    const list = event.currentTarget
    const dayCell = list.closest("[data-monthly-drag-target='dayCell']")
    dayCell?.classList.remove("border-amber-400")

    if (!this.draggedSession) return

    const newDayOfWeek = parseInt(dayCell?.dataset.dayOfWeek ?? "0", 10)
    const targetDate = dayCell?.dataset.date
    const updateUrl = this.draggedSession.dataset.updateUrl
    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    // Move DOM element
    list.appendChild(this.draggedSession)

    try {
      const response = await fetch(updateUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ planned_session: { day_of_week: newDayOfWeek, target_date: targetDate } })
      })

      if (!response.ok) throw new Error("Update failed")
    } catch (error) {
      // Revert on failure
      if (this.originList) {
        this.originList.appendChild(this.draggedSession)
      }
    }
  }

  showSessionDetail(event) {
    // Don't open modal if we were dragging
    if (this.wasDragging) {
      this.wasDragging = false
      return
    }

    const el = event.currentTarget
    const modal = document.querySelector("[data-controller='session-modal']")
    if (!modal) return

    const controller = this.application.getControllerForElementAndIdentifier(modal, "session-modal")
    if (!controller) return

    controller.open({
      title: el.dataset.sessionTitle || "Session",
      type: el.dataset.sessionType || "",
      intensity: el.dataset.sessionIntensity || "",
      duration: el.dataset.sessionDuration || "",
      description: el.dataset.sessionDescription || "",
      status: el.dataset.sessionStatus || "",
      url: el.dataset.sessionUrl || "#"
    })
  }
}
