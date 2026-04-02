import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "modalTitle",
    "editPanel",
    "libraryPanel",
    "name",
    "nameSuggestions",
    "nameHint",
    "sets",
    "reps",
    "duration",
    "rest",
    "description",
    "notes",
    "librarySearch",
    "libraryList",
    "librarySuggestions",
    "libraryBrowse",
    "libraryBrowseToggle",
    "libraryHint",
    "keepPrescription",
    "keepPrescriptionWrapper",
    "error"
  ]

  static values = {
    url: String,
    exercises: Array,
    library: Array
  }

  connect() {
    this.exercises = Array.isArray(this.exercisesValue) ? this.exercisesValue.map((ex) => this.ensureId({ ...ex })) : []
    this.libraryEntries = Array.isArray(this.libraryValue) ? this.libraryValue : []
    this.mode = null
    this.editIndex = null
    this.selectedLibraryEntry = null
    this.renderLibrarySuggestions()
  }

  edit(event) {
    const index = this.exerciseIndexFromEvent(event)
    if (index === null) return

    this.mode = "edit"
    this.editIndex = index
    const exercise = this.exercises[index]
    this.selectedLibraryEntry = this.entryForExercise(exercise)
    this.populateForm(exercise)
    this.showEditPanel("Edit Exercise")
  }

  swap(event) {
    const index = this.exerciseIndexFromEvent(event)
    if (index === null) return

    this.mode = "swap"
    this.editIndex = index
    this.showLibraryPanel("Swap Exercise", true)
  }

  remove(event) {
    const index = this.exerciseIndexFromEvent(event)
    if (index === null) return

    const exercise = this.exercises[index]
    const name = exercise?.name || exercise?.title || "this exercise"
    if (!window.confirm(`Remove ${name}?`)) return

    this.exercises.splice(index, 1)
    this.saveExercises()
  }

  addCustom() {
    this.mode = "add_custom"
    this.editIndex = null
    this.selectedLibraryEntry = null
    this.populateForm({})
    this.showEditPanel("Add Exercise")
  }

  addFromLibrary() {
    this.mode = "add_library"
    this.editIndex = null
    this.showLibraryPanel("Add From Library", false)
  }

  addExercise() {
    this.mode = "add"
    this.editIndex = null
    this.selectedLibraryEntry = null
    this.populateForm({})
    this.showEditPanel("Add Exercise")
    this.refreshNameSuggestions()
    if (this.hasNameTarget) this.nameTarget.focus()
  }

  saveForm(event) {
    event.preventDefault()
    const exercise = this.exerciseFromForm()
    const existing = this.editIndex !== null ? this.exercises[this.editIndex] || {} : {}

    if (!exercise.name) {
      this.setError("Name is required.")
      return
    }

    this.setError("")

    const libraryEntry = this.selectedLibraryEntry
    let libraryData = {}

    if (libraryEntry) {
      libraryData = {
        source: "library",
        library_entry_id: libraryEntry.id,
        category: libraryEntry.category
      }
      if (!exercise.description && libraryEntry.description) {
        libraryData.description = libraryEntry.description
      }
    } else if (this.mode === "edit" && existing.library_entry_id && exercise.name === existing.name) {
      libraryData = {
        source: existing.source,
        library_entry_id: existing.library_entry_id,
        category: existing.category
      }
      if (!exercise.description && existing.description) {
        libraryData.description = existing.description
      }
    } else if (this.mode !== "edit") {
      libraryData = { source: "custom" }
    }

    if (this.mode === "edit" && this.editIndex !== null) {
      const updated = this.ensureId({ ...existing, ...exercise, ...libraryData })
      if (!libraryEntry && existing.library_entry_id && exercise.name !== existing.name) {
        delete updated.library_entry_id
        delete updated.category
        if (updated.source === "library") updated.source = "custom"
      }
      this.exercises[this.editIndex] = updated
    } else {
      this.exercises.push(this.ensureId({ ...exercise, ...libraryData }))
    }

    this.saveExercises()
  }

  selectLibrary(event) {
    const entryId = event.currentTarget.dataset.entryId
    const entry = this.libraryEntries.find((item) => String(item.id) === String(entryId))
    if (!entry) return

    if (this.mode === "swap" && this.editIndex !== null) {
      const keepPrescription = this.hasKeepPrescriptionTarget ? this.keepPrescriptionTarget.checked : true
      const existing = this.exercises[this.editIndex] || {}

      const base = {
        id: existing.id || this.generateId(),
        name: entry.name,
        source: "library",
        library_entry_id: entry.id,
        category: entry.category,
        description: entry.description || existing.description
      }

      if (keepPrescription) {
        this.exercises[this.editIndex] = {
          ...base,
          sets: existing.sets,
          reps: existing.reps,
          duration: existing.duration,
          rest: existing.rest,
          notes: existing.notes
        }
      } else {
        this.exercises[this.editIndex] = base
      }
    } else {
      const exercise = this.ensureId({
        name: entry.name,
        source: "library",
        library_entry_id: entry.id,
        category: entry.category,
        description: entry.description
      })
      this.exercises.push(exercise)
    }

    this.saveExercises()
  }

  filterLibrary() {
    const query = this.librarySearchTarget.value
    this.renderLibrarySuggestions(query)
    if (this.isBrowseOpen()) this.renderLibraryList(query)
  }

  handleNameInput() {
    if (!this.hasNameTarget) return
    const value = this.nameTarget.value
    if (this.selectedLibraryEntry && value.trim() !== this.selectedLibraryEntry.name) {
      this.selectedLibraryEntry = null
    }
    this.renderNameSuggestions(value)
  }

  close(event) {
    if (event) event.preventDefault()
    this.hideModal()
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) this.hideModal()
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.hideModal()
  }

  showEditPanel(title) {
    this.modalTitleTarget.textContent = title
    this.editPanelTarget.classList.remove("hidden")
    this.libraryPanelTarget.classList.add("hidden")
    this.showModal()
    this.refreshNameSuggestions()
  }

  showLibraryPanel(title, showKeepPrescription) {
    this.modalTitleTarget.textContent = title
    this.editPanelTarget.classList.add("hidden")
    this.libraryPanelTarget.classList.remove("hidden")

    if (this.hasKeepPrescriptionWrapperTarget) {
      this.keepPrescriptionWrapperTarget.classList.toggle("hidden", !showKeepPrescription)
    }
    if (this.hasKeepPrescriptionTarget && showKeepPrescription) {
      this.keepPrescriptionTarget.checked = true
    }

    this.showModal()
    if (this.hasLibrarySearchTarget) {
      this.librarySearchTarget.value = ""
    }
    this.renderLibrarySuggestions()
    this.closeBrowse()
    this.librarySearchTarget.focus()
  }

  showModal() {
    this.setError("")
    this.modalTarget.classList.remove("hidden")
  }

  hideModal() {
    this.modalTarget.classList.add("hidden")
  }

  populateForm(exercise) {
    if (this.hasNameTarget) this.nameTarget.value = exercise.name || exercise.title || ""
    if (this.hasSetsTarget) this.setsTarget.value = exercise.sets || ""
    if (this.hasRepsTarget) this.repsTarget.value = exercise.reps || ""
    if (this.hasDurationTarget) this.durationTarget.value = exercise.duration || ""
    if (this.hasRestTarget) this.restTarget.value = exercise.rest || ""
    if (this.hasDescriptionTarget) this.descriptionTarget.value = exercise.description || ""
    if (this.hasNotesTarget) this.notesTarget.value = exercise.notes || ""
  }

  exerciseFromForm() {
    return this.compactExercise({
      name: this.stringValue(this.nameTarget.value),
      sets: this.stringValue(this.setsTarget.value),
      reps: this.stringValue(this.repsTarget.value),
      duration: this.stringValue(this.durationTarget.value),
      rest: this.stringValue(this.restTarget.value),
      description: this.stringValue(this.descriptionTarget.value),
      notes: this.stringValue(this.notesTarget.value)
    })
  }

  compactExercise(exercise) {
    const compacted = {}
    Object.entries(exercise).forEach(([key, value]) => {
      if (value === null || value === undefined || value === "") return
      compacted[key] = value
    })
    return compacted
  }

  ensureId(exercise) {
    if (!exercise.id) exercise.id = this.generateId()
    return exercise
  }

  generateId() {
    return crypto?.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(16).slice(2)}`
  }

  exerciseIndexFromEvent(event) {
    const card = event.currentTarget.closest("[data-exercise-index]")
    if (!card) return null
    const index = parseInt(card.dataset.exerciseIndex, 10)
    return Number.isNaN(index) ? null : index
  }

  async saveExercises() {
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
        body: JSON.stringify({ exercises: this.exercises })
      })

      if (!response.ok) throw new Error("Save failed")
      window.location.reload()
    } catch (error) {
      this.setError("Could not save exercises. Try again.")
    }
  }

  selectNameSuggestion(event) {
    const entryId = event.currentTarget.dataset.entryId
    const entry = this.libraryEntries.find((item) => String(item.id) === String(entryId))
    if (!entry) return

    const previous = this.selectedLibraryEntry
    this.selectedLibraryEntry = entry
    if (this.hasNameTarget) this.nameTarget.value = entry.name

    if (this.hasDescriptionTarget) {
      const currentDescription = this.descriptionTarget.value?.trim() || ""
      if (!currentDescription || (previous && previous.description === currentDescription)) {
        this.descriptionTarget.value = entry.description || ""
      }
    }

    this.renderNameSuggestions(entry.name)
  }

  renderLibraryList(query = "") {
    if (!this.hasLibraryListTarget) return

    const normalizedQuery = query.toLowerCase().trim()
    const entries = this.libraryEntries.filter((entry) => {
      if (!normalizedQuery) return true
      return entry.name.toLowerCase().includes(normalizedQuery) || entry.category?.toLowerCase().includes(normalizedQuery)
    })

    this.libraryListTarget.innerHTML = ""

    if (!entries.length) {
      const empty = document.createElement("div")
      empty.className = "text-sm text-slate-400"
      empty.textContent = "No matches"
      this.libraryListTarget.appendChild(empty)
      return
    }

    entries.forEach((entry) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "w-full text-left rounded-lg border border-slate-800 bg-slate-950/60 px-3 py-2 text-sm text-slate-200 hover:border-slate-600 hover:bg-slate-900 transition"
      button.dataset.entryId = entry.id
      button.dataset.action = "click->session-exercises#selectLibrary"

      const name = document.createElement("div")
      name.className = "font-medium"
      name.textContent = entry.name

      const meta = document.createElement("div")
      meta.className = "text-xs text-slate-400"
      meta.textContent = entry.category ? entry.category.replace(/_/g, " ") : ""

      button.appendChild(name)
      button.appendChild(meta)
      this.libraryListTarget.appendChild(button)
    })
  }

  renderLibrarySuggestions(query = "") {
    if (!this.hasLibrarySuggestionsTarget) return
    this.renderSuggestionList({
      query,
      suggestionsTarget: this.librarySuggestionsTarget,
      hintTarget: this.libraryHintTarget,
      onSelectAction: "click->session-exercises#selectLibrary",
      emptyHint: "Start typing to see matches.",
      noMatchHint: "No matches."
    })
  }

  setLibraryHint(message) {
    if (!this.hasLibraryHintTarget) return
    this.libraryHintTarget.textContent = message
    this.libraryHintTarget.classList.toggle("hidden", !message)
  }

  toggleBrowse() {
    if (!this.hasLibraryBrowseTarget) return
    if (this.isBrowseOpen()) {
      this.closeBrowse()
    } else {
      this.openBrowse()
    }
  }

  openBrowse() {
    if (!this.hasLibraryBrowseTarget) return
    this.libraryBrowseTarget.classList.remove("hidden")
    this.updateBrowseToggleLabel(true)
    this.renderLibraryList(this.librarySearchTarget.value)
  }

  closeBrowse() {
    if (!this.hasLibraryBrowseTarget) return
    this.libraryBrowseTarget.classList.add("hidden")
    this.updateBrowseToggleLabel(false)
  }

  isBrowseOpen() {
    if (!this.hasLibraryBrowseTarget) return false
    return !this.libraryBrowseTarget.classList.contains("hidden")
  }

  updateBrowseToggleLabel(isOpen) {
    if (!this.hasLibraryBrowseToggleTarget) return
    this.libraryBrowseToggleTarget.textContent = isOpen ? "Hide browse" : "Browse all"
  }

  renderNameSuggestions(query = "") {
    if (!this.hasNameSuggestionsTarget) return
    this.renderSuggestionList({
      query,
      suggestionsTarget: this.nameSuggestionsTarget,
      hintTarget: this.nameHintTarget,
      onSelectAction: "click->session-exercises#selectNameSuggestion",
      emptyHint: "Start typing to see matches.",
      noMatchHint: "No matches. Keep typing to add custom."
    })
  }

  refreshNameSuggestions() {
    if (!this.hasNameTarget) return
    this.renderNameSuggestions(this.nameTarget.value)
  }

  renderSuggestionList({ query, suggestionsTarget, hintTarget, onSelectAction, emptyHint, noMatchHint }) {
    const normalizedQuery = (query || "").toLowerCase().trim()
    suggestionsTarget.innerHTML = ""

    if (!normalizedQuery) {
      this.setHint(hintTarget, emptyHint)
      return
    }

    const scored = this.suggestionsForQuery(normalizedQuery)

    if (!scored.length) {
      this.setHint(hintTarget, noMatchHint)
      return
    }

    this.setHint(hintTarget, "")

    scored.forEach(({ entry }) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className =
        "w-full text-left px-3 py-2 text-sm text-slate-200 hover:bg-slate-900/70 transition"
      button.dataset.entryId = entry.id
      button.dataset.action = onSelectAction

      const name = document.createElement("div")
      name.className = "font-medium"
      name.textContent = entry.name

      const meta = document.createElement("div")
      meta.className = "text-xs text-slate-400"
      meta.textContent = entry.category ? entry.category.replace(/_/g, " ") : ""

      button.appendChild(name)
      button.appendChild(meta)
      suggestionsTarget.appendChild(button)
    })
  }

  suggestionsForQuery(normalizedQuery) {
    return this.libraryEntries
      .filter((entry) => {
        return (
          entry.name.toLowerCase().includes(normalizedQuery) ||
          entry.category?.toLowerCase().includes(normalizedQuery)
        )
      })
      .map((entry) => {
        const name = entry.name.toLowerCase()
        let score = 3
        if (name.startsWith(normalizedQuery)) score = 0
        else if (name.includes(normalizedQuery)) score = 1
        else if (entry.category?.toLowerCase().includes(normalizedQuery)) score = 2
        return { entry, score }
      })
      .sort((a, b) => {
        if (a.score !== b.score) return a.score - b.score
        return a.entry.name.localeCompare(b.entry.name)
      })
      .slice(0, 6)
  }

  setHint(target, message) {
    if (!target) return
    target.textContent = message
    target.classList.toggle("hidden", !message)
  }

  entryForExercise(exercise) {
    if (!exercise) return null
    if (exercise.library_entry_id) {
      const match = this.libraryEntries.find((entry) => String(entry.id) === String(exercise.library_entry_id))
      if (match) return match
    }
    return null
  }

  stringValue(value) {
    if (value === null || value === undefined) return ""
    return String(value).trim()
  }

  setError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = message
    this.errorTarget.classList.toggle("hidden", !message)
  }
}
