import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["range", "value"]

  connect() {
    this.update()
    this.rangeTarget.addEventListener("input", () => this.update())
  }

  update() {
    if (this.hasValueTarget) {
      this.valueTarget.textContent = this.rangeTarget.value
    }
  }
}
