import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const content = this.templateTarget.content.cloneNode(true)
    this.listTarget.appendChild(content)
  }

  remove(event) {
    const item = event.currentTarget.closest("[data-injury-field]")
    if (item) item.remove()
  }
}
