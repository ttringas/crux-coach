import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    this.sync()
  }

  open() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove("-translate-x-full")
      this.sidebarTarget.setAttribute("aria-hidden", "false")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
    }
    document.body.classList.add("overflow-hidden")
    document.documentElement.classList.add("overflow-hidden")
  }

  close() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.add("-translate-x-full")
      this.sidebarTarget.setAttribute("aria-hidden", "true")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
    document.body.classList.remove("overflow-hidden")
    document.documentElement.classList.remove("overflow-hidden")
  }

  beforeCache() {
    this.close()
  }

  closeOnNavigate(event) {
    if (!event.target.closest("a, button, form")) return
    this.close()
  }

  sync() {
    if (!this.hasSidebarTarget || !this.hasOverlayTarget) {
      document.body.classList.remove("overflow-hidden")
      document.documentElement.classList.remove("overflow-hidden")
      return
    }

    if (this.sidebarTarget.classList.contains("-translate-x-full")) {
      this.sidebarTarget.setAttribute("aria-hidden", "true")
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
