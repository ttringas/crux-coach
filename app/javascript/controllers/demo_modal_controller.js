import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "frame", "title"]

  open(event) {
    const url = event.currentTarget.dataset.demoModalUrl || event.currentTarget.getAttribute("href")
    if (!url) return

    event.preventDefault()
    if (this.hasFrameTarget) this.frameTarget.src = url
    if (this.hasTitleTarget) this.titleTarget.textContent = event.currentTarget.dataset.demoTitle || "Exercise Demo"
    if (this.hasModalTarget) this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    if (this.hasModalTarget) this.modalTarget.classList.add("hidden")
    if (this.hasFrameTarget) this.frameTarget.src = "about:blank"
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }
}
