import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "editor", "input", "form"]

  edit() {
    this.displayTarget.classList.add("hidden")
    this.editorTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    this.editorTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }

  save(event) {
    // Let the form submit naturally via Turbo
  }
}
