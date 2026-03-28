import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const active = this.tabTargets[0]?.dataset.tabsName
    if (active) this.showByName(active)
  }

  show(event) {
    event.preventDefault()
    const name = event.currentTarget.dataset.tabsName
    this.showByName(name)
  }

  showByName(name) {
    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.tabsName === name
      tab.classList.toggle("text-slate-300", isActive)
      tab.classList.toggle("text-slate-400", !isActive)
      tab.classList.toggle("border-amber-500", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("border-b-2", true)
    })

    this.panelTargets.forEach((panel) => {
      const isActive = panel.dataset.tabsName === name
      panel.classList.toggle("hidden", !isActive)
    })
  }
}
