import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status", "startDate", "endDate"]

  submit() {
    if (this.hasStatusTarget) {
      this.statusTarget.classList.remove("hidden")
    }
    // Defer disabling the button so the native form submit fires first
    setTimeout(() => {
      if (this.hasButtonTarget) {
        this.buttonTarget.disabled = true
        this.buttonTarget.classList.add("opacity-50")
        this.buttonTarget.textContent = "Generating..."
      }
    }, 50)
  }
}
