import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sessionList", "emptyState", "session"]

  connect() {
    this.draggedSession = null
    this.originList = null
    this.originNextSibling = null

    this.boundDragStart = this.handleDragStart.bind(this)
    this.boundDragEnd = this.handleDragEnd.bind(this)

    this.sessionTargets.forEach((session) => {
      session.setAttribute("draggable", "true")
      session.addEventListener("dragstart", this.boundDragStart)
      session.addEventListener("dragend", this.boundDragEnd)
    })

    this.sessionListTargets.forEach((list) => {
      list.addEventListener("dragover", this.handleDragOver)
      list.addEventListener("drop", this.handleDrop)
      list.addEventListener("dragenter", this.handleDragEnter)
      list.addEventListener("dragleave", this.handleDragLeave)
    })

    this.updateAllEmptyStates()
  }

  disconnect() {
    this.sessionTargets.forEach((session) => {
      session.removeEventListener("dragstart", this.boundDragStart)
      session.removeEventListener("dragend", this.boundDragEnd)
    })

    this.sessionListTargets.forEach((list) => {
      list.removeEventListener("dragover", this.handleDragOver)
      list.removeEventListener("drop", this.handleDrop)
      list.removeEventListener("dragenter", this.handleDragEnter)
      list.removeEventListener("dragleave", this.handleDragLeave)
    })
  }

  handleDragStart(event) {
    this.draggedSession = event.currentTarget
    this.originList = this.draggedSession.parentElement
    this.originNextSibling = this.draggedSession.nextElementSibling

    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = "move"
      event.dataTransfer.setData("text/plain", this.draggedSession.dataset.sessionId)
    }

    this.draggedSession.classList.add("opacity-50", "ring-2", "ring-amber-400/60")
    this.sessionListTargets.forEach((list) => list.classList.add("ring-2", "ring-amber-400/30", "bg-slate-800/80"))
  }

  handleDragEnd = () => {
    if (this.draggedSession) {
      this.draggedSession.classList.remove("opacity-50", "ring-2", "ring-amber-400/60")
    }
    this.sessionListTargets.forEach((list) => list.classList.remove("ring-2", "ring-amber-400/30", "bg-slate-800/80"))
    this.draggedSession = null
    this.originList = null
    this.originNextSibling = null
    this.updateAllEmptyStates()
  }

  handleDragEnter = (event) => {
    event.preventDefault()
    event.currentTarget.classList.add("border-amber-400", "bg-slate-800/80")
  }

  handleDragLeave = (event) => {
    if (event.currentTarget.contains(event.relatedTarget)) return
    event.currentTarget.classList.remove("border-amber-400", "bg-slate-800/80")
  }

  handleDragOver = (event) => {
    event.preventDefault()
    if (!this.draggedSession) return

    const list = event.currentTarget
    const next = this.insertionPoint(list, event.clientY)

    if (next) {
      list.insertBefore(this.draggedSession, next)
    } else {
      list.appendChild(this.draggedSession)
    }
  }

  handleDrop = async (event) => {
    event.preventDefault()
    const list = event.currentTarget
    list.classList.remove("border-amber-400", "bg-slate-800/80")
    if (!this.draggedSession) return

    const dayIndex = this.dayIndexForList(list)
    if (dayIndex === null) return

    const updateUrl = this.draggedSession.dataset.updateUrl
    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    try {
      this.draggedSession.dataset.dayIndex = String(dayIndex)
      await this.persistOrdering(this.originList, token)
      if (list !== this.originList) await this.persistOrdering(list, token)

      const sessions = Array.from(list.querySelectorAll("[data-session-id]"))
      const newPosition = sessions.indexOf(this.draggedSession)
      const response = await fetch(updateUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ planned_session: { day_of_week: dayIndex, position: newPosition } })
      })

      if (!response.ok) throw new Error("Update failed")
      this.draggedSession.dataset.position = String(newPosition)
    } catch (error) {
      if (this.originList) {
        this.originList.insertBefore(this.draggedSession, this.originNextSibling)
      }
    } finally {
      this.updateAllEmptyStates()
    }
  }

  insertionPoint(list, clientY) {
    const siblings = Array.from(list.querySelectorAll("[data-session-id]"))
      .filter((session) => session !== this.draggedSession)

    return siblings.find((session) => {
      const rect = session.getBoundingClientRect()
      return clientY < rect.top + rect.height / 2
    }) || null
  }

  async persistOrdering(list, token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")) {
    if (!list) return

    const dayIndex = this.dayIndexForList(list)
    const sessions = Array.from(list.querySelectorAll("[data-session-id]"))

    for (const [index, session] of sessions.entries()) {
      session.dataset.position = String(index)
      session.dataset.dayIndex = String(dayIndex)
      const updateUrl = session.dataset.updateUrl
      if (!updateUrl) continue

      await fetch(updateUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ planned_session: { day_of_week: dayIndex, position: index } })
      })
    }
  }

  dayIndexForList(list) {
    const day = list?.closest("[data-day-index]")
    if (!day) return null
    const value = parseInt(day.dataset.dayIndex || "", 10)
    return Number.isNaN(value) ? null : value
  }

  updateAllEmptyStates() {
    this.sessionListTargets.forEach((list) => {
      const day = list.closest("[data-day-index]")
      if (!day) return
      const emptyState = day.querySelector("[data-plan-drag-target='emptyState']")
      if (!emptyState) return
      emptyState.classList.toggle("hidden", list.querySelectorAll("[data-session-id]").length > 0)
    })
  }
}
