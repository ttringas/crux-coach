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
    if (!this.hasButtonTarget) return
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Generating..."
    this.buttonTarget.classList.add("opacity-70")

    if (this.hasStatusTarget) {
      this.statusTarget.classList.remove("hidden")
    }
  }
}
