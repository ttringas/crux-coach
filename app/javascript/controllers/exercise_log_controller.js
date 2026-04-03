import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saveStatus", "sessionNotes", "perceivedExertion", "energyLevel", "fingerSoreness", "generalSoreness"]
  static outlets = ["speech-input"]
  static values = { url: String, debounce: { type: Number, default: 800 } }

  connect() {
    this.saveTimeout = null
    this.boundSpeechHandler = this.handleSpeechResult.bind(this)
    this.element.addEventListener("speech-input:result", this.boundSpeechHandler)
  }

  disconnect() {
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.element.removeEventListener("speech-input:result", this.boundSpeechHandler)
  }

  queueSave(event) {
    if (event && event.target) {
      if (event.target.type === "checkbox") {
        this.applyRecommendedValues(event.target)
      }
      this.updateCardState(event.target)
    }

    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.setSaveStatus("Saving...")
    this.saveTimeout = setTimeout(() => this.save(), this.debounceValue)
  }

  handleSpeechResult(event) {
    const input = event.target?.querySelector("[data-speech-input-target='input']")
    if (!input) return

    this.queueSave({ target: input })
  }

  updateCardState(target) {
    const card = target.closest("[data-exercise-index]")
    if (!card) return
    const checkboxes = Array.from(card.querySelectorAll("input[type='checkbox']"))
    if (checkboxes.length === 0) return
    const anyChecked = checkboxes.some((checkbox) => checkbox.checked)

    if (anyChecked) {
      card.classList.add("bg-green-500/5", "border-green-500/20")
      card.classList.remove("border-slate-800")
    } else {
      card.classList.remove("bg-green-500/5", "border-green-500/20")
      card.classList.add("border-slate-800")
    }
  }

  applyRecommendedValues(checkbox) {
    if (!checkbox.checked) return
    const row = checkbox.closest("[data-set-key]")
    if (!row) return

    const repsInput = row.querySelector("[data-set-field='actual_reps']")
    if (repsInput && !repsInput.value) {
      const recommended = this.recommendedNumber(repsInput.dataset.recommendedValue || repsInput.placeholder)
      if (recommended !== null) repsInput.value = recommended
    }

    const weightInput = row.querySelector("[data-set-field='actual_weight']")
    if (weightInput && !weightInput.value) {
      const recommended = this.recommendedNumber(weightInput.dataset.recommendedValue || weightInput.placeholder)
      if (recommended !== null) weightInput.value = recommended
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
    const exerciseLogs = []
    Array.from(this.element.querySelectorAll("[data-exercise-index]")).forEach((card) => {
      const index = parseInt(card.dataset.exerciseIndex, 10)
      const notes = this.stringValue(card.querySelector("[data-exercise-log-field='notes']")?.value)

      const setRows = Array.from(card.querySelectorAll("[data-set-key]"))
      setRows.forEach((row) => {
        const setKey = row.dataset.setKey
        const setIndex = parseInt(row.dataset.setIndex, 10)
        const completed = row.querySelector("input[type='checkbox']")?.checked || false
        const actualReps = this.integerValue(row.querySelector("[data-set-field='actual_reps']")?.value)
        const actualWeight = this.floatValue(row.querySelector("[data-set-field='actual_weight']")?.value)

        const hasData = completed || actualReps !== null || actualWeight !== null || notes
        if (!hasData) return

        exerciseLogs.push({
          set_key: setKey,
          exercise_index: index,
          set_index: Number.isNaN(setIndex) ? null : setIndex,
          completed: completed,
          actual_reps: actualReps,
          actual_weight: actualWeight,
          notes: notes
        })
      })
    })

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

  recommendedNumber(value) {
    if (!value) return null
    const matches = String(value).match(/\d+/g)
    if (!matches || matches.length === 0) return null
    const parsed = parseInt(matches[matches.length - 1], 10)
    return Number.isNaN(parsed) ? null : parsed
  }

  setSaveStatus(text) {
    if (this.hasSaveStatusTarget) {
      this.saveStatusTarget.textContent = text
    }
  }
}
