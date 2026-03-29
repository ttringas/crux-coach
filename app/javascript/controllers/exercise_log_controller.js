import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saveStatus", "sessionNotes", "perceivedExertion", "energyLevel", "fingerSoreness", "generalSoreness"]
  static values = { url: String, debounce: { type: Number, default: 800 } }

  connect() {
    this.saveTimeout = null
  }

  queueSave(event) {
    if (event && event.target) {
      this.updateCardState(event.target)
    }

    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.setSaveStatus("Saving...")
    this.saveTimeout = setTimeout(() => this.save(), this.debounceValue)
  }

  toggle(event) {
    const card = event.currentTarget.closest("[data-exercise-index]")
    if (!card) return
    const details = card.querySelector("[data-exercise-details]")
    if (details) details.classList.toggle("hidden")
  }

  updateCardState(target) {
    const card = target.closest("[data-exercise-index]")
    if (!card) return
    const checkbox = card.querySelector("input[type='checkbox']")
    if (!checkbox) return

    if (checkbox.checked) {
      card.classList.add("bg-green-500/5", "border-green-500/20")
      card.classList.remove("border-slate-800")
    } else {
      card.classList.remove("bg-green-500/5", "border-green-500/20")
      card.classList.add("border-slate-800")
    }
  }

  async save() {
    if (!this.urlValue) return

    const payload = { planned_session: this.buildPayload() }
    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) throw new Error("Save failed")
      this.setSaveStatus("Saved")
      setTimeout(() => this.setSaveStatus(""), 1500)
    } catch (error) {
      this.setSaveStatus("Save failed")
    }
  }

  buildPayload() {
    const exerciseLogs = Array.from(this.element.querySelectorAll("[data-exercise-index]")).map((card) => {
      const index = parseInt(card.dataset.exerciseIndex, 10)
      const completed = card.querySelector("input[type='checkbox']")?.checked || false
      const actualSets = this.integerValue(card.querySelector("[data-exercise-log-field='actual_sets']")?.value)
      const actualReps = this.integerValue(card.querySelector("[data-exercise-log-field='actual_reps']")?.value)
      const actualWeight = this.floatValue(card.querySelector("[data-exercise-log-field='actual_weight']")?.value)
      const actualDuration = this.stringValue(card.querySelector("[data-exercise-log-field='actual_duration']")?.value)
      const notes = this.stringValue(card.querySelector("[data-exercise-log-field='notes']")?.value)

      const hasData = completed || actualSets !== null || actualReps !== null || actualWeight !== null || actualDuration || notes
      if (!hasData) return null

      return {
        exercise_index: index,
        completed: completed,
        actual_sets: actualSets,
        actual_reps: actualReps,
        actual_weight: actualWeight,
        actual_duration: actualDuration,
        notes: notes
      }
    }).filter(Boolean)

    return {
      exercise_logs: exerciseLogs,
      session_notes: this.stringValue(this.hasSessionNotesTarget ? this.sessionNotesTarget.value : null),
      perceived_exertion: this.integerValue(this.hasPerceivedExertionTarget ? this.perceivedExertionTarget.value : null),
      energy_level: this.integerValue(this.hasEnergyLevelTarget ? this.energyLevelTarget.value : null),
      finger_soreness: this.integerValue(this.hasFingerSorenessTarget ? this.fingerSorenessTarget.value : null),
      general_soreness: this.integerValue(this.hasGeneralSorenessTarget ? this.generalSorenessTarget.value : null)
    }
  }

  integerValue(value) {
    if (value === null || value === undefined || value === "") return null
    const parsed = parseInt(value, 10)
    return Number.isNaN(parsed) ? null : parsed
  }

  floatValue(value) {
    if (value === null || value === undefined || value === "") return null
    const parsed = parseFloat(value)
    return Number.isNaN(parsed) ? null : parsed
  }

  stringValue(value) {
    if (value === null || value === undefined) return null
    const trimmed = String(value).trim()
    return trimmed.length ? trimmed : null
  }

  setSaveStatus(text) {
    if (this.hasSaveStatusTarget) {
      this.saveStatusTarget.textContent = text
    }
  }
}
