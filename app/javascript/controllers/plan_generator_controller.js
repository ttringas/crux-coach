import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  submit(event) {
    event.preventDefault()
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
  }
}
