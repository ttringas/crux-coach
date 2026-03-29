import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "preview", "rawInput", "saveButton"]

  connect() {
    this.toggleSave()
  }

  parse(event) {
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Parsing..."
    this.buttonTarget.classList.add("opacity-70")

    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = "<div class=\"mt-4 bg-slate-800/60 border border-slate-700 rounded-lg p-4 text-sm text-slate-300\">Parsing complete. Review the structured summary below before saving.</div>"
    }
  }

  toggleSave() {
    if (!this.hasSaveButtonTarget || !this.hasRawInputTarget) return

    const hasContent = this.rawInputTarget.value.trim().length > 0
    this.saveButtonTarget.disabled = !hasContent
    this.saveButtonTarget.classList.toggle("opacity-50", !hasContent)
    this.saveButtonTarget.classList.toggle("cursor-not-allowed", !hasContent)
  }
}
