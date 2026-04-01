import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status"]

  submit(event) {
    this.setLoading()
  }

  connect() {
    if (this.hasButtonTarget) {
      this.element.addEventListener("submit", () => this.setLoading())
    }
  }

  setLoading() {
    if (this.hasStatusTarget) {
      this.statusTarget.classList.remove("hidden")
    }
    // Defer disabling so the native form submit fires first
    setTimeout(() => {
      if (!this.hasButtonTarget) return
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = "Generating..."
      this.buttonTarget.classList.add("opacity-70")
    }, 50)
  }
}
