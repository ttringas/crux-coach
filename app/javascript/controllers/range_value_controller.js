import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    this.update()
  }

  update() {
    if (!this.hasInputTarget || !this.hasOutputTarget) return
    this.outputTarget.textContent = this.inputTarget.value
  }
}
